using System;
using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Windows.Forms;
using PayPalRetailSDK;

namespace RetailSDKTestApp.WinForms
{
    public partial class Form1 : Form
    {
        private const string SdkTokenKey = "sdkToken";
        private Merchant _merchant;
        private readonly List<PaymentDevice> _devices = new List<PaymentDevice>();
        private TransactionContext _context;
        private bool _sdkInitialized;

        public Form1()
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

            InitializeComponent();
            Setup();
        }

        private async void Setup()
        {
            //TODO Temporary fix until we put proper certificates on the software update server for stage
            ServicePointManager.ServerCertificateValidationCallback = delegate { return true; };
            btnCharge.Enabled = false;
            _sdkInitialized = RetailSDK.Initialize(this);
            UpdateStatus("Initialized Retail SDK");

            RetailSDK.DeviceDiscovered += (sender, device) =>
            {
                _devices.Add(device);
                UpdateStatus($"Discovered {device.Name ?? device.SerialNumber ?? "a device"}");
                device.Connected += paymentDevice =>
                {
                    UpdateStatus($"Connected to {device.Name ?? device.SerialNumber}");
                    TryEnableChargeButton();
                };
            };

            txtSdkToken.Text = SdkToken;
            UpdateStatus("Initializing Merchant...");
            _merchant = await RetailSDK.InitializeMerchant(txtSdkToken.Text.Trim());
            UpdateStatus($"Initialized {_merchant.EmailAddress}");
            TryEnableChargeButton();
        }

        private string SdkToken
        {
            get
            {
                try
                {
                    var token = Properties.Settings.Default[SdkTokenKey].ToString();
                    if (string.IsNullOrWhiteSpace(token))
                    {
                        token = DefaultSdkToken;
                    }

                    return token;
                }
                catch (Exception ex)
                {
                    Console.WriteLine(ex);
                }
                return string.Empty;
            }
            set
            {
                Properties.Settings.Default[SdkTokenKey] = value;
                Properties.Settings.Default.Save();
            }
        }

        private string DefaultSdkToken => new StreamReader(Assembly.GetExecutingAssembly().GetManifestResourceStream("RetailSDKTestApp.WinForms.testToken.txt")).ReadToEnd();

        private void btnCharge_Click(object sender, EventArgs e)
        {
            if (!CanStartTransaction())
            {
                return;
            }

            decimal amount;
            amount = decimal.TryParse(txtAmount.Text, out amount) ? amount : 1;
            var invoice = new Invoice(null);
            invoice.AddItem("Amount", decimal.One, amount, "", "");
            UpdateStatus("Started Transaction");
            _merchant.IsCertificationMode = cbTestMode.Checked;
            _context = RetailSDK.CreateTransaction(invoice);
            _context.Completed += (context, error, record) =>
            {
                UpdateStatus(error?.Message ?? $"Successfully completed transaction {record.TransactionNumber}", error != null);
            };
            _context.Begin(true);
        }

        private void btnInitializeMerchant_Click(object sender, EventArgs e)
        {
            if (!CanInitializeMerchant())
            {
                return;
            }

            SdkToken = txtSdkToken.Text.Trim();
            RestartApp();
        }

        private void btnReset_Click(object sender, EventArgs e)
        {
            SdkToken = DefaultSdkToken;
            RestartApp();
        }

        private void RestartApp()
        {
            MessageBox.Show("Exiting... Please re-open the App");
            Application.Exit();
        }

        private bool CanStartTransaction()
        {
            return _sdkInitialized && _merchant != null && _devices.Any(x => x.IsConnected());
        }

        private bool CanInitializeMerchant()
        {
            return _sdkInitialized;
        }

        private void UpdateStatus(string message, bool isError = false)
        {
            if (lblStatus.InvokeRequired)
            {
                lblStatus.BeginInvoke(new Action(() =>
                {
                    lblStatus.Text = message;
                    lblStatus.ForeColor = isError ? Color.Red : Color.Black;
                }));
            }
            else
            {
                lblStatus.Text = message;
                lblStatus.ForeColor = isError ? Color.Red : Color.Black;
            }
        }

        private void TryEnableChargeButton()
        {
            var enable = _devices.Any() && _devices[0].IsConnected() && _merchant != null;
            if (btnCharge.InvokeRequired)
            {
                btnCharge.BeginInvoke(new Action(() =>
                {
                    btnCharge.Enabled = enable;
                    btnExtractReaderLogs.Enabled = enable;
                }));
            }
            else
            {
                btnCharge.Enabled = enable;
                btnExtractReaderLogs.Enabled = enable;
            }
        }
        private void btnExtractReaderLogs_Click(object sender, EventArgs e)
        {
            int devicecounter = 0;
            foreach (var device in _devices)
            {
                try
                {
                    devicecounter++;
                    UpdateStatus($"Extracting logs from {device.Name ?? device.SerialNumber ?? "a device"}...");
                    this.UseWaitCursor = true;
                    device.ExtractReaderLogs(error =>
                    {
                        devicecounter--;
                        UpdateStatus($"Logs extracted from {device.Name ?? device.SerialNumber ?? "a device"}");
                        if (devicecounter < 1)
                        {
                            this.UseWaitCursor = false;
                        }

                    });
                }
                catch (Exception ex)
                {
                    devicecounter--;
                    if (devicecounter < 1)
                    {
                        this.UseWaitCursor = false;
                    }
                    UpdateStatus("Error in extracting reader logs: " + ex.Message);
                }
            }
        }

        private void txtSdkToken_MouseClick(object sender, MouseEventArgs e)
        {
            txtSdkToken.SelectAll();
            txtSdkToken.Focus();
        }
    }
}
