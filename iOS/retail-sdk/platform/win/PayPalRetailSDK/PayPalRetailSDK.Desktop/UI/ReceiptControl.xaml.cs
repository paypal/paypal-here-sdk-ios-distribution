using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media.Imaging;

namespace PayPalRetailSDK.UI
{
    /// <summary>
    /// Interaction logic for ReceiptControl.xaml
    /// </summary>
    public partial class ReceiptControl : UserControl
    {
        private static ReceiptControl _sInstance;
        private static ReceiptViewDelegate _callback;
        private static readonly object Locker = new object();
        private static WpfOnWinForm _wpfOnWinForm;
        private static BlurredBackground _backgroundPanel;
        private ReceiptViewContent _viewContent;
        public delegate void ReceiptViewDelegate(string emailOrrSms);

        private enum SendReceiptBy
        {
            Email,
            Sms
        }

        private ReceiptControl()
        {
            this.InitializeComponent();
        }

        public static BlurredBackground ObscurebackgroundPanel
        {
            get
            {
                lock (Locker)
                {
                    if (_backgroundPanel != null)
                    {
                        return _backgroundPanel;
                    }

                    _backgroundPanel = new BlurredBackground();
                }
                return _backgroundPanel;
            }
        }

        private static ReceiptControl GetInstance()
        {
            lock (Locker)
            {
                if (_sInstance != null) return _sInstance;

                _sInstance = new ReceiptControl();
                _sInstance.LeftButton.Click += (sender, eventArgs) =>
                {
                    ShowReceiptOptions(_sInstance);
                };
                _sInstance.RightButton.Click += (sender, eventArgs) =>
                {
                    Dismiss(_sInstance.ReceiptTarget.Text);
                };
                _sInstance.PreferEmailReceipt.Click += (sender, eventArgs) =>
                {
                    var maskedEmail = _sInstance._viewContent.ReceiptOptionsViewContent.MaskedEmail;
                    if (string.IsNullOrWhiteSpace(maskedEmail))
                    {
                        ShowReceiptTargetPanel(_sInstance, SendReceiptBy.Email);
                    }
                    else
                    {
                        Dismiss(maskedEmail);
                    }
                };
                _sInstance.EditEmail.MouseUp += (sender, e) =>
                {
                    ShowReceiptTargetPanel(_sInstance, SendReceiptBy.Email);
                };
                _sInstance.PreferTextReceipt.Click += (sender, eventArgs) =>
                {
                    var maskedPhone = _sInstance._viewContent.ReceiptOptionsViewContent.MaskedPhone;
                    if (string.IsNullOrWhiteSpace(maskedPhone))
                    {
                        ShowReceiptTargetPanel(_sInstance, SendReceiptBy.Sms);
                    }
                    else
                    {
                        Dismiss(maskedPhone);
                    }
                };
                _sInstance.EditPhoneNumber.MouseUp += (sender, e) =>
                {
                    ShowReceiptTargetPanel(_sInstance, SendReceiptBy.Sms);
                };
                _sInstance.NoReceipt.Click += (sender, eventArgs) =>
                {
                    Dismiss(null);
                };

                BitmapImage img;
                if (UiUtils.TryGetBitmapImage("img_edit_receipt.png", out img))
                {
                    _sInstance.EditEmail.Source = img;
                    _sInstance.EditPhoneNumber.Source = img;
                }

                if (RetailSDK.IsWpfApp)
                {
                    Application.Current.MainWindow.LayoutUpdated += MainWindow_LayoutUpdated;
                }
            }

            return _sInstance;
        }

        public static void Show(ReceiptViewContent viewContent, ReceiptViewDelegate callback)
        {
            _callback = callback;
            var receiptView = GetInstance();
            receiptView._viewContent = viewContent;
            receiptView.Status.Text = viewContent.ReceiptOptionsViewContent.Message;
            receiptView.Title.Text = viewContent.ReceiptOptionsViewContent.Title;
            receiptView.PreferEmailReceipt.Content = viewContent.ReceiptOptionsViewContent.EmailButtonTitle;
            receiptView.PreferTextReceipt.Content = viewContent.ReceiptOptionsViewContent.SmsButtonTitle;
            receiptView.Disclaimer.Text = viewContent.ReceiptOptionsViewContent.Disclaimer;
            receiptView.NoReceipt.Content = viewContent.ReceiptOptionsViewContent.NoThanksButtonTitle;

            if (string.IsNullOrWhiteSpace(viewContent.ReceiptOptionsViewContent.MaskedEmail))
            {
                receiptView.PreferEmailReceipt.Content = viewContent.ReceiptOptionsViewContent.EmailButtonTitle;
                receiptView.EditEmail.Visibility = Visibility.Collapsed;
            }
            else
            {
                receiptView.PreferEmailReceipt.Content = viewContent.ReceiptOptionsViewContent.MaskedEmail;
                receiptView.EditEmail.Visibility = Visibility.Visible;
            }

            if (string.IsNullOrWhiteSpace(viewContent.ReceiptOptionsViewContent.MaskedPhone))
            {
                receiptView.PreferTextReceipt.Content = viewContent.ReceiptOptionsViewContent.SmsButtonTitle;
                receiptView.EditPhoneNumber.Visibility = Visibility.Collapsed;
            }
            else
            {
                receiptView.PreferTextReceipt.Content = viewContent.ReceiptOptionsViewContent.MaskedPhone;
                receiptView.EditPhoneNumber.Visibility = Visibility.Visible;
            }

            BitmapImage img;
            UiUtils.TryGetBitmapImage(viewContent.ReceiptOptionsViewContent.TitleIconFilename, out img);
            if (img == null)
            {
                receiptView.StatusIcon.Visibility = Visibility.Collapsed;
            }
            else
            {
                receiptView.StatusIcon.Visibility = Visibility.Visible;
                receiptView.StatusIcon.Source = img;
            }

            ShowReceiptOptions(receiptView);
            if (receiptView.Popup.Child == null)
            {
                return;
            }

            receiptView.Popup.Child = null;

            if (RetailSDK.IsWpfApp)
            {
                RetailSDK.WpfContentGridForUi.Children.Add(ObscurebackgroundPanel);
                RetailSDK.WpfContentGridForUi.Children.Add(receiptView.MainGrid);
            }
            else
            {
                _wpfOnWinForm = receiptView.MainGrid.ShowWithParentFormLock(RetailSDK.WinFormAlertParent);
            }
        }

        private static void Dismiss(string receiptTarget)
        {
            //We are not using GetInstance here because we do not want to create an instance if we do not already have one
            if (_sInstance == null || _sInstance.Popup.Child != null)
            {
                return;
            }

            _sInstance.ReceiptTarget.Text = string.Empty;

            RetailSDK.RunOnUIThreadAsync(() =>
            {
                if (RetailSDK.IsWpfApp)
                {
                    RetailSDK.WpfContentGridForUi.Children.Remove(ObscurebackgroundPanel);
                    RetailSDK.WpfContentGridForUi.Children.Remove(_sInstance.MainGrid);
                    _sInstance.Popup.Child = _sInstance.MainGrid;
                }
                else
                {
                    _wpfOnWinForm.ElementHost.Child = null;
                    _sInstance.Popup.Child = _sInstance.MainGrid;
                    _wpfOnWinForm.Popup.Close();
                }
            });

            _callback(receiptTarget);
        }

        private static void MainWindow_LayoutUpdated(object sender, EventArgs e)
        {
            ObscurebackgroundPanel.Height = ObscurebackgroundPanel.CanvasBackground.Height = Application.Current.MainWindow.ActualHeight;
            ObscurebackgroundPanel.Width = ObscurebackgroundPanel.CanvasBackground.Width = Application.Current.MainWindow.ActualWidth;
        }

        private static void ShowReceiptTargetPanel(ReceiptControl receipt, SendReceiptBy sendBy)
        {
            receipt.ReceiptOptions.Visibility = Visibility.Collapsed;
            receipt.ReceiptDestination.Visibility = Visibility.Visible;
            receipt.LeftButton.Visibility = Visibility.Visible;
            receipt.RightButton.Visibility = Visibility.Visible;
            receipt.StatusIcon.Visibility = Visibility.Collapsed;
            receipt.ReceiptTarget.Text = string.Empty;

            if (sendBy == SendReceiptBy.Email)
            {
                var viewContent = receipt._viewContent.ReceiptEmailEntryViewContent;
                receipt.Title.Text = viewContent.Title;
                receipt.SendToDisclaimer.Text = viewContent.Disclaimer;
                receipt.RightButton.Content = viewContent.SendButtonTitle;
                BitmapImage img;
                if (UiUtils.TryGetBitmapImage("ic_email.png", out img))
                {
                    receipt.IconSendTo.Source = img;
                }
            }

            if (sendBy == SendReceiptBy.Sms)
            {
                var viewContent = receipt._viewContent.ReceiptSMSEntryViewContent;
                receipt.Title.Text = viewContent.Title;
                receipt.SendToDisclaimer.Text = viewContent.Disclaimer;
                receipt.RightButton.Content = viewContent.SendButtonTitle;
                BitmapImage img;
                if (UiUtils.TryGetBitmapImage("ic_text.png", out img))
                {
                    receipt.IconSendTo.Source = img;
                }
            }
        }

        private static void ShowReceiptOptions(ReceiptControl receipt)
        {
            receipt.ReceiptOptions.Visibility = Visibility.Visible;
            receipt.ReceiptDestination.Visibility = Visibility.Collapsed;
            receipt.LeftButton.Visibility = Visibility.Collapsed;
            receipt.RightButton.Visibility = Visibility.Collapsed;
        }
    }
}
