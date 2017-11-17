using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using System.Windows.Media.Effects;
using PayPalRetailSDK;
using RetailSDKTestApp.Desktop;

namespace RetailSDKTestApp.Net4
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private TransactionContext _context;
        private Invoice _invoiceForRefund;
        private Merchant _merchant;
        private readonly ObservableCollection<Device> _devices = new ObservableCollection<Device>();
        private readonly SolidColorBrush _normalBrush = new SolidColorBrush(Color.FromArgb(0xff, 0x00, 0x9c, 0xde));
        private readonly SolidColorBrush _successBrush = new SolidColorBrush(Color.FromArgb(0xff, 0x6c, 0xb3, 0x3f));
        private readonly SolidColorBrush _failureBrush = Brushes.Yellow;
        private const double DefaultSignatureRequiredAbove = 50.00;
        private bool _beginMerchantInitialize;

        public MainWindow()
        {
            AppDomain.CurrentDomain.UnhandledException += (sender, e) =>
            {
                try
                {
                    MessageBox.Show("Unhandled exception: " + e.ExceptionObject);
                }
                catch (Exception)
                {
                    // ignored
                }
            };

            //TODO Temporary fix until we put proper certificates on the software update server for stage
            ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            InitializeComponent();
            Application.Current.Exit += Current_Exit;
            SignatureRequiredAbove.Text = DefaultSignatureRequiredAbove.ToString("F");
            RetailSDK.Initialize();
            TryEnablePayments();
            RetailSDK.DeviceDiscovered += (sender, device) =>
            {
                var deviceId = device.Id;
                _devices.RemoveAll(x => x.Id == deviceId);
                _devices.Add(new Device
                {
                    Id = deviceId,
                    SerialNumber = "n/a",
                    Status = DeviceStatus.Connecting,
                    SdkDevice = device
                });
                Dispatcher.BeginInvoke(new Action(() =>
                {
                    MessageTextBlock.Text = $"Attempting connection with {deviceId}...";
                    ConnectedDevices.ItemsSource = _devices;
                }));
                device.Connected += device_Connected;
                device.Disconnected += device_Disconnected;
                device.ConnectionError += device_ConnectionError;
                device.UpdateRequired += device_UpdateRequired;
            };

            MessageTextBlock.Text = "SDK Initialized.";
            var sdkToken = new StreamReader(Assembly.GetExecutingAssembly().GetManifestResourceStream("RetailSDKTestApp.Net4.testToken.txt")).ReadToEnd();
            SdkTokens.ViewModel.LoadFromCache();
            SdkTokens.ViewModel.AddToken(sdkToken);
            SdkTokens.TokenChanged += (sender, e) =>
            {
                if (!_beginMerchantInitialize)
                {
                    InitializeMerchant(e.Value);
                    return;
                }

                foreach (var device in _devices.Where(device => device.SdkDevice.IsConnected()))
                {
                    device.SdkDevice.Disconnect(error => { });
                }
                System.Diagnostics.Process.Start(Application.ResourceAssembly.Location);
                Application.Current.Shutdown();
            };

            AmountField.TextChanged += (sender, args) =>
            {
                if (_context?.Invoice != null && TransactionAmount.HasValue)
                {
                    _context.Invoice.Items[0].UnitPrice = TransactionAmount;
                }
                TryEnablePayments();
            };
            GratuityField.TextChanged += (sender, args) =>
            {
                if (_context?.Invoice != null && GratuityAmount.HasValue)
                {
                    _context.Invoice.GratuityAmount = GratuityAmount;
                }
            };
        }

        private void Current_Exit(object sender, ExitEventArgs e)
        {
            try
            {
                foreach (var device in _devices)
                {
                    device.SdkDevice.Disconnect(error => {});
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error on exit {ex}");
            }
        }

        private decimal? TransactionAmount
        {
            get
            {
                decimal amount;
                return decimal.TryParse(AmountField.Text, out amount) ? (decimal?)amount : null;
            }
        }

        private decimal? GratuityAmount
        {
            get
            {
                decimal amount;
                return decimal.TryParse(GratuityField.Text, out amount) ? (decimal?)amount : null;
            }
        }

        private void device_ConnectionError(PaymentDevice device, RetailSDKException error)
        {
            var myDevice = GetDevice(device.Id);
            Dispatcher.BeginInvoke(new Action(() =>
            {
                myDevice.Status = DeviceStatus.ConnectionFailed;
                MessageTextBlock.Text = $"{myDevice.Id} connection failed with error {error.Message}";
            }));
        }

        void device_UpdateRequired(PaymentDevice device, DeviceUpdate update)
        {
            var myDevice = GetDevice(device.Id);
            Dispatcher.BeginInvoke(new Action(() =>
            {
                myDevice.UpdateAvailable = true;
                myDevice.Status = DeviceStatus.NeedsSoftwareUpdate;
                MessageTextBlock.Text = $"{myDevice.Id} requires software update";
            }));

            if (!_allowAutoUpdates)
            {
                return;
            }

            Dispatcher.BeginInvoke(new Action(() =>
            {
                myDevice.UpdateAvailable = false;
                MessageTextBlock.Text = $"Updating software on {myDevice.Id}";
                myDevice.Status = DeviceStatus.Updating;
            }));

            device.PendingUpdate.Begin(false, (error, upgraded) =>
            {
                UpdateComplete(myDevice, error, upgraded);
            });

            device.PendingUpdate.ReconnectReader += (sender, time) =>
            {
                Dispatcher.BeginInvoke(new Action(() =>
                {
                    myDevice.Status = DeviceStatus.UnplugAndReplug;
                }));
            };
        }

        private void TryEnablePayments()
        {
            try
            {
                var activeDevice = GetActiveDevice();
                var allowPayments = _merchant != null && activeDevice != null && activeDevice.SdkDevice.IsConnected() &&
                                    (activeDevice.Status == DeviceStatus.Connected ||
                                     activeDevice.Status == DeviceStatus.NeedsSoftwareUpdate ||
                                     activeDevice.Status == DeviceStatus.UpdateSuccessful);
                Dispatcher.BeginInvoke(new Action(() =>
                {
                    ChargeButton.IsEnabled = allowPayments && TransactionAmount.HasValue && TransactionAmount.Value > 0;
                }));
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex);
            }
        }
        
        private void device_Disconnected(PaymentDevice device, RetailSDKException error)
        {
            var deviceId = device.Id;
            Dispatcher.BeginInvoke(new Action(() =>
            {
                var myDevice = GetDevice(device.Id);
                myDevice.Status = DeviceStatus.NotConnected;
                MessageTextBlock.Text = $"Disconnected from {deviceId}";
                TryEnablePayments();
            }));
        }

        private void device_Connected(PaymentDevice device)
        {
            var serialNumber = device.SerialNumber;
            var deviceId = device.Id;
            Dispatcher.BeginInvoke(new Action(() =>
            {
                var myDevice = GetDevice(device.Id);
                if (!_devices.Any(x => x.ActivePaymentDevice))
                {
                    myDevice.ActivePaymentDevice = true;
                }
                if (myDevice.Status != DeviceStatus.NeedsSoftwareUpdate && myDevice.Status != DeviceStatus.Updating)
                {
                    myDevice.Status = DeviceStatus.Connected;
                }
                myDevice.SerialNumber = serialNumber;
                MessageTextBlock.Text = $"Connected to {deviceId}";
                TryEnablePayments();
            }));
        }

        private async void InitializeMerchant(string token)
        {
            try
            {
                _beginMerchantInitialize = true;
                MerchantStatusPanel.Background = _normalBrush;
                MerchantStatus.Foreground = Brushes.White;
                MerchantStatus.Text = "Initializing Merchant...";
                _merchant = await RetailSDK.InitializeMerchant(token);
                var emailId = _merchant.EmailAddress;
                Dispatcher.BeginInvoke(new Action(() =>
                {
                    _context = _context ?? CreateTxContext();
                    MerchantStatus.Text = "Merchant initialized: " + emailId;
                    MerchantStatusPanel.Background = _successBrush;
                }));
            }
            catch (Exception x)
            {
                Dispatcher.BeginInvoke(new Action(() =>
                {
                    MerchantStatus.Text = "Merchant init failed: " + x.ToString().Substring(0, x.Message.Length > 100 ? 100 : x.ToString().Length);
                    MerchantStatus.Foreground = Brushes.Black;
                    MerchantStatusPanel.Background = _failureBrush;
                }));
            }
            finally
            {
                TryEnablePayments();
            }
        }

        private TransactionContext CreateTxContext()
        {
            if (_merchant == null)
            {
                return null;
            }

            try
            {
                decimal amount, tip;
                amount = decimal.TryParse(AmountField.Text, out amount) ? amount : 1;
                tip = decimal.TryParse(GratuityField.Text, out tip) ? tip : 0;
                var invoice = new Invoice(null);
                invoice.AddItem("Amount", decimal.One, amount, "", "");
                if (tip > 0)
                {
                    invoice.GratuityAmount = tip;
                }
                return RetailSDK.CreateTransaction(invoice);
            }
            catch (Exception ex)
            {
                Dispatcher.BeginInvoke(new Action(() =>
                {
                    MerchantStatus.Text = "Transaction creation failed with error: " + ex.ToString().Substring(0, ex.Message.Length > 100 ? 100 : ex.ToString().Length);
                    MerchantStatus.Foreground = Brushes.Black;
                    MerchantStatusPanel.Background = _failureBrush;
                }));
            }

            return null;
        }

        private void RefundMostRecentPayment(object sender, RoutedEventArgs e)
        {
            if (_invoiceForRefund == null)
            {
                return;
            }

            RefundOptions refundOptions;
            Effect = new BlurEffect();
            Opacity = 0.5;
            try
            {
                refundOptions = new RefundOptions
                {
                    TransactionId = _invoiceForRefund.Payments.Count > 0 ? _invoiceForRefund.Payments[0].TransactionID : string.Empty,
                    Amount = _invoiceForRefund.Total,
                    Owner = this,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner
                };
                refundOptions.ShowDialog();
            }
            finally
            {
                Effect = null;
                Opacity = 1.0;
            }

            if (refundOptions.DialogResult.HasValue && !refundOptions.DialogResult.Value)
            {
                return;
            }

            var context = RetailSDK.CreateTransaction(_invoiceForRefund);
            context.Completed += context_Completed;
            MessageTextBlock.Text = $"Refunding transaction for {refundOptions.Amount} on {GetActiveDevice().Id}";
            PrepareSdkForPayment(context, _merchant);
            if (!refundOptions.CardPresent)
            {
                context.BeginRefund(false, refundOptions.Amount).ContinueWithCard(null);
            }
            else
            {
                context.BeginRefund(true, refundOptions.Amount);
            }
        }

        private void BeginPayment(object sender, RoutedEventArgs e)
        {
            MessageTextBlock.Text = $"Created new transaction on {GetActiveDevice().Id}";
            _context = _context ?? CreateTxContext();
            _context.Completed += context_Completed;
            PrepareSdkForPayment(_context, _merchant);
            _context.Begin(true);
        }

        private void PrepareSdkForPayment(TransactionContext context, Merchant merchant)
        {
            context.SetSignatureCollector(receiver =>
            {
                receiver.AcquireSignature();
            });

            context.PaymentDevices = new List<PaymentDevice>
            {
                GetActiveDevice().SdkDevice
            };

            decimal signatureRequiredAbove;
            if (decimal.TryParse(SignatureRequiredAbove.Text, out signatureRequiredAbove) &&
                signatureRequiredAbove > 0)
            {
                merchant.SignatureRequiredAbove = signatureRequiredAbove;
            }
            else
            {
                SignatureRequiredAbove.Text = DefaultSignatureRequiredAbove.ToString("F");
            }
            merchant.IsCertificationMode = EnableCertificationMode.IsChecked.Value;
        }

        void context_Completed(TransactionContext sender, RetailSDKException error, TransactionRecord record)
        {
            var enableRefund = (sender.IsRefund() && error != null) || (!sender.IsRefund() && error == null);
            var activeDeviceId = sender.PaymentDevices[0].Id;
            Dispatcher.BeginInvoke(new Action(() =>
            {
                var activeDevice = GetDevice(activeDeviceId);
                RefundButton.IsEnabled = enableRefund;
                activeDevice.UpdateAvailable = false;
                MessageTextBlock.Text = "Transaction Completed " + (error?.ToString() ?? "no error");
            }));

            if (error == null)
            {
                _invoiceForRefund = sender.Invoice;
            }
            _context = null;
        }

        private void UpdateDevice(object sender, RoutedEventArgs e)
        {
            var device = (Device)((FrameworkElement)sender).DataContext;
            device.SdkDevice.PendingUpdate?.Offer((error, upgraded) =>
            {
                UpdateComplete(device, error, upgraded);
            });
        }

        private DeviceStatus _oldStatus;
        private void ExtractLogs(object sender, RoutedEventArgs e)
        {
            var device = (Device)((FrameworkElement)sender).DataContext;
            _oldStatus = device.Status;
            device.Status = DeviceStatus.DownloadingDeviceLogs;
            TryEnablePayments();
            device.SdkDevice.ExtractReaderLogs((error) =>
            {
                ExtractComplete(device, error);
            });
        }

        private void ExtractComplete(Device device, RetailSDKException error)
        {
            Dispatcher.BeginInvoke(new Action(() =>
            {
                device.Status = _oldStatus;
                TryEnablePayments();
                MessageTextBlock.Text = error != null
                    ? $"Extract logs failed on {device.Id} with error {error.Message}"
                    : $"Extract logs on {device.Id} was successful";
            }));
        }

        private void UpdateComplete(Device device, RetailSDKException error, bool updateStatus)
        {
            Dispatcher.BeginInvoke(new Action(() =>
            {
                device.Status = error != null || !updateStatus ? DeviceStatus.UpdateFailed : DeviceStatus.UpdateSuccessful;
                device.UpdateAvailable = false;
                MessageTextBlock.Text = error != null
                    ? $"Update failed on {device.Id} with error {error.Message}"
                    : $"Software upgrade on {device.Id} was successful";
            }));
        }

        private bool _allowAutoUpdates;
        private void AutoUpdateChecked(object sender, RoutedEventArgs e)
        {
            _allowAutoUpdates = true;
        }

        private void AutoUpdateUnChecked(object sender, RoutedEventArgs e)
        {
            _allowAutoUpdates = false;
        }

        private Device GetActiveDevice()
        {
            return _devices.FirstOrDefault(x => x.ActivePaymentDevice);
        }

        private Device GetDevice(string deviceId)
        {
            return _devices.First(x => x.Id == deviceId);
        }

        private void ToggleConnection(object sender, RoutedEventArgs e)
        {
            var device = (Device)((FrameworkElement)sender).DataContext;
            if (device.Status == DeviceStatus.Connected)
            {
                device.SdkDevice.Disconnect(error =>
                {
                    var errMessage = error?.Message;
                    Dispatcher.BeginInvoke(new Action(() =>
                    {
                        device.Status = errMessage == null ? DeviceStatus.NotConnected : device.Status;
                        MessageTextBlock.Text = error != null
                            ? $"{device.Id} disconnection failed with error {error.Message}"
                            : $"Successfully disconnected {device.Id}";
                        TryEnablePayments();
                    }));
                });
            }
            else
            {
                device.Status = DeviceStatus.Connecting;
                device.SdkDevice.Connect(error =>
                {
                    var errMessage = error?.Message;
                    Dispatcher.BeginInvoke(new Action(() =>
                    {
                        device.Status = errMessage == null ? DeviceStatus.Connected : DeviceStatus.ConnectionFailed;
                        MessageTextBlock.Text = error != null
                            ? $"{device.Id} connection with error {error.Message}"
                            : $"Successfully connected {device.Id}";
                        TryEnablePayments();
                    }));
                });
            }
        }
    }
}
