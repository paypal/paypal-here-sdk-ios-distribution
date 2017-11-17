using System;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media.Imaging;

namespace PayPalRetailSDK.UI
{
    /// <summary>
    /// Interaction logic for SignatureControl.xaml
    /// </summary>
    public partial class SignatureControl : UserControl
    {
        private static SignatureControl _sInstance;
        private static SignatureViewDelegate _callback;
        private static readonly object Locker = new object();
        private static WpfOnWinForm _wpfOnWinForm;
        private static BlurredBackground _backgroundPanel;
        public delegate void SignatureViewDelegate(string base64Signature, bool cancelRequested);

        public class SignatureViewHandle
        {
            public void Dismiss()
            {
                DismissSignatureControl();
            }
        }
        
        private SignatureControl()
        {
            InitializeComponent();
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

        private static SignatureControl GetInstance()
        {
            lock (Locker)
            {
                if (_sInstance != null)
                {
                    return _sInstance;
                }
                _sInstance = new SignatureControl();
                _sInstance.CancelButton.Click += cancelButton_Click;
                _sInstance.RightButton.Click += doneButton_Click;
                _sInstance.SignatureStrokes.StrokeCollected += signatureStrokes_StrokeCollected;
                _sInstance.SignatureStrokes.PreviewMouseDown += SignatureStrokes_PreviewMouseDown;
                if (RetailSDK.IsWpfApp)
                {
                    Application.Current.MainWindow.LayoutUpdated += MainWindow_LayoutUpdated;
                }
            }

            return _sInstance;
        }

        private static void UpdateClearSignature(bool isEnabled)
        {
            BitmapImage img;
            if (isEnabled)
            {
                _sInstance.ClearSignature.MouseUp += clearButton_Click;
                if (UiUtils.TryGetBitmapImage("ic_clear_signature.png", out img))
                {
                    _sInstance.ClearSignature.Source = img;
                }
            }
            else
            {
                _sInstance.ClearSignature.MouseUp -= clearButton_Click;
                if (UiUtils.TryGetBitmapImage("ic_clear_signature_disabled.png", out img))
                {
                    _sInstance.ClearSignature.Source = img;
                }
            }
        }

        static void SignatureStrokes_PreviewMouseDown(object sender, MouseButtonEventArgs e)
        {
            UpdateClearSignature(isEnabled: true);
            _sInstance.WaterMark.Visibility = Visibility.Hidden;
        }

        public static SignatureViewHandle Show(string title, string signHereLabel, string footerText, string cancelButtonText, SignatureViewDelegate callback)
        {
            var handle = new SignatureViewHandle();
            _callback = callback;
            var signControl = GetInstance();
            UpdateClearSignature(isEnabled: false);
            signControl.Title.Text = title;
            signControl.FooterText.Content = footerText;
            signControl.RightButton.IsEnabled = false;
            signControl.WaterMark.Content = signHereLabel;
            signControl.WaterMark.Visibility = Visibility.Visible;
            signControl.SignatureStrokes.Strokes.Clear();

            if (string.IsNullOrWhiteSpace(cancelButtonText))
            {
                signControl.CancelButton.Visibility = Visibility.Hidden;
            }
            else
            {
                signControl.CancelButton.Visibility = Visibility.Visible;
                signControl.CancelButton.Content = cancelButtonText;
            }

            if (signControl.Popup.Child == null)
            {
                return handle;
            }

            signControl.Popup.Child = null;
            if (RetailSDK.IsWpfApp)
            {
                RetailSDK.WpfContentGridForUi.Children.Add(ObscurebackgroundPanel);
                RetailSDK.WpfContentGridForUi.Children.Add(signControl.MainPanel);
            }
            else
            {
                _wpfOnWinForm = signControl.MainPanel.ShowWithParentFormLock(RetailSDK.WinFormAlertParent);
            }

            return handle;
        }

        private static void doneButton_Click(object sender, RoutedEventArgs e)
        {
            var signControl = GetInstance();
            var memorySig = UiUtils.GetScaledImageFromFrameworkElement(300, 200, signControl.SignatureStrokes);
            DismissSignatureControl();
            _callback(Convert.ToBase64String(memorySig.ToArray()), false);
        }

        private static void DismissSignatureControl()
        {
            RetailSDK.RunOnUIThreadAsync(() =>
            {
                //We are not using GetInstance here because we do not want to create an instance if we do not already have one
                if (_sInstance == null || _sInstance.Popup.Child != null)
                {
                    return;
                }

                if (RetailSDK.IsWpfApp)
                {
                    RetailSDK.WpfContentGridForUi.Children.Remove(ObscurebackgroundPanel);
                    RetailSDK.WpfContentGridForUi.Children.Remove(_sInstance.MainPanel);
                    _sInstance.Popup.Child = _sInstance.MainPanel;
                }
                else
                {
                    _wpfOnWinForm.ElementHost.Child = null;
                    _sInstance.Popup.Child = _sInstance.MainPanel;
                    _wpfOnWinForm.Popup.Close();
                }
            });
        }

        private static void MainWindow_LayoutUpdated(object sender, EventArgs e)
        {
            ObscurebackgroundPanel.Height = ObscurebackgroundPanel.CanvasBackground.Height = Application.Current.MainWindow.ActualHeight;
            ObscurebackgroundPanel.Width = ObscurebackgroundPanel.CanvasBackground.Width = Application.Current.MainWindow.ActualWidth;
        }

        private static void signatureStrokes_StrokeCollected(object sender, InkCanvasStrokeCollectedEventArgs e)
        {
            var signControl = GetInstance();
            signControl.WaterMark.Visibility = Visibility.Hidden;
            signControl.RightButton.IsEnabled = true;
        }

        private static void clearButton_Click(object sender, RoutedEventArgs e)
        {
            var signControl = GetInstance();
            signControl.SignatureStrokes.Strokes.Clear();
            signControl.RightButton.IsEnabled = false;
            signControl.WaterMark.Visibility = Visibility.Visible;
            UpdateClearSignature(isEnabled: false);
        }

        private static void cancelButton_Click(object sender, RoutedEventArgs e)
        {
            _callback(null, true);
        }
    }
}
