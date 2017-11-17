using System;
using System.Collections.Generic;
using System.IO;
using System.Media;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Markup;
using System.Windows.Media.Imaging;
using PayPalRetailSDK.UI;

// The User Control item template is documented at http://go.microsoft.com/fwlink/?LinkId=234236
namespace PayPalRetailSDK.Desktop.UI
{
    /// <summary>
    /// Alert view for WinPhone/WinRT
    /// reference: http://stackoverflow.com/questions/11593978/in-winrt-api-how-to-accept-user-input-in-a-dialog-just-like-in-weather-and-fina
    /// </summary>
    public sealed partial class AlertView : UserControl
    {
        private const string LogComponentName = "AlertView";

        /// <summary>
        /// The AlertViewHandle protects against out-of-turn calls to the exposed capabilities of the singleton
        /// </summary>
        public class AlertViewHandle
        {
            private readonly int _counter;
            internal AlertViewDelegate Callback;

            public AlertViewHandle(int counter, AlertViewDelegate callback)
            {
                _counter = counter;
                Callback = callback;
            }
            public void Dismiss()
            {
                if (_counter == _sShowCount)
                {
                    AlertView.Dismiss();
                }
            }

            public bool IsShowing()
            {
                return AlertView.IsShowing();
            }

            public void SetTitle(String title)
            {
                if (_counter == _sShowCount)
                {
                    AlertView.SetTitle(title);
                }
            }
            public void SetMessage(String message)
            {
                if (_counter == _sShowCount)
                {
                    AlertView.SetMessage(message);
                }
            }
        }

        public delegate void AlertViewDelegate(AlertViewHandle alertView, int selectedButton);

        private AlertView()
        {
            InitializeComponent();
            _player = UiUtils.GetMediaPlayer();
        }

        private static readonly object Locker = new object();
        private static AlertView _sInstance;
        private static AlertViewHandle _sCurrent;
        private static int _sShowCount;
        private static WpfOnWinForm _wpfOnWinForm;
        private static BlurredBackground _backgroundPanel;
        private readonly ISdkMediaPlayer _player;
        private static bool _isShowing;

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

        public static AlertView GetInstance()
        {
            lock (Locker)
            {
                if (_sInstance != null)
                {
                    return _sInstance;
                }

                _sInstance = new AlertView();
                if (RetailSDK.IsWpfApp)
                {
                    Application.Current.MainWindow.LayoutUpdated += MainWindow_LayoutUpdated;
                }
            }
            return _sInstance;
        }

        // Make sure you call this from the UI thread
        public static AlertViewHandle Show(string title, string message, bool showActivity, string cancel, List<string> otherButtonNames, 
            string imageIcon, string audioFile, int audioPlayCount, AlertViewDelegate callback)
        {
            var handle = new AlertViewHandle(++_sShowCount, callback);
            if (!string.IsNullOrWhiteSpace(audioFile))
            {
                PlayAudio(audioFile, audioPlayCount);
            }

            if (string.IsNullOrWhiteSpace(title) && string.IsNullOrWhiteSpace(message))
            {
                return handle;
            }

            var alert = GetInstance();
            alert.Title.Text = title ?? string.Empty;
            alert.Message.Visibility = string.IsNullOrWhiteSpace(message) ? Visibility.Collapsed : Visibility.Visible;
            alert.Message.Text = message ?? string.Empty;
            alert.Cancel.Visibility = string.IsNullOrEmpty(cancel) ? Visibility.Collapsed : Visibility.Visible;
            alert.Cancel.Content = cancel ?? string.Empty;
            alert.Cancel.Tag = otherButtonNames?.Count ?? 0;
            alert.Progress.Visibility = showActivity ? Visibility.Visible : Visibility.Collapsed;
            alert.ButtonPanel.Children.Clear();
            alert.ButtonPanel.Visibility = Visibility.Collapsed;
            alert.Icon.Visibility = Visibility.Collapsed;

            if (otherButtonNames != null && otherButtonNames.Count > 0)
            {
                alert.ButtonPanel.Visibility = Visibility.Visible;
                var tag = 0;
                foreach (var name in otherButtonNames)
                {
                    var newButton = XamlClone(alert.Cancel);
                    newButton.Visibility = Visibility.Visible;
                    newButton.Content = name;
                    newButton.Tag = tag++;
                    newButton.Name = $"otherButton_{newButton.Tag}";
                    newButton.Click += alert.ButtonClick;
                    alert.ButtonPanel.Children.Add(newButton);
                }
            }

            BitmapImage bmp;
            if (imageIcon != null && UiUtils.TryGetBitmapImage(imageIcon, out bmp))
            {
                alert.Icon.Visibility = Visibility.Visible;
                alert.Icon.Source = bmp;
            }

            _sCurrent = handle;

            if (alert.Popup.Child == null) return handle;
            alert.Popup.Child = null;

            if (RetailSDK.IsWpfApp)
            {
                RetailSDK.WpfContentGridForUi.Children.Add(ObscurebackgroundPanel);
                RetailSDK.WpfContentGridForUi.Children.Add(alert.MainGrid);
            }
            else
            {
                _wpfOnWinForm = alert.MainGrid.ShowWithParentFormLock(RetailSDK.WinFormAlertParent);
            }

            _isShowing = true;
            return handle;
        }

        private static void PlayAudioFie(string fileName)
        {
            if (_sInstance._player == null)
            {
                return;
            }

            try
            {
                var executablePath = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location) +
                                     "\\Resources\\Sounds\\";
                var fileLocation = Path.Combine(executablePath, fileName);
                _sInstance._player.PlayAudio(fileLocation);
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("Error", LogComponentName, $"PlayAudioFie logged an exception {ex}");
            }
        }

        private static async Task PlayAudibleBeep()
        {
            try
            {
                var task = Task.Factory.StartNew(() =>
                {
                    SystemSounds.Beep.Play();
                    Thread.Sleep(400); //Without this pause, the subsequent Beep sounds would overlap
                });
                await task;
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("Error", LogComponentName, $"PlayAudibleBeep logged an exception {ex}");
            }
        }

        private static async void PlayAudio(string fileName, int playCount)
        {
            for (var i = 0; i < playCount; i++)
            {
                if (fileName.Equals("beep", StringComparison.OrdinalIgnoreCase))
                {
                    await PlayAudibleBeep();
                }
                else
                {
                    PlayAudioFie(fileName);
                }
            }

        }

        private static void MainWindow_LayoutUpdated(object sender, EventArgs e)
        {
            ObscurebackgroundPanel.Height = ObscurebackgroundPanel.CanvasBackground.Height = Application.Current.MainWindow.ActualHeight;
            ObscurebackgroundPanel.Width = ObscurebackgroundPanel.CanvasBackground.Width = Application.Current.MainWindow.ActualWidth;
        }

        /// <summary>
        /// Set the title of the alert on the UI Dispatcher
        /// </summary>
        /// <param name="value">Title to be displayed</param>
        private static void SetTitle(string value)
        {
            RetailSDK.RunOnUIThreadAsync(() =>
            {
                GetInstance().Title.Text = value;
            });
        }

        /// <summary>
        /// Set the message on the alert
        /// </summary>
        /// <param name="value">Message to be displayed</param>
        private static void SetMessage(string value)
        {
            RetailSDK.RunOnUIThreadAsync(() =>
            {
                GetInstance().Message.Visibility = string.IsNullOrWhiteSpace(value) ? Visibility.Collapsed : Visibility.Visible;
                GetInstance().Message.Text = value;
            });
        }

        private static bool IsShowing()
        {
            return _isShowing;
        }

        /// <summary>
        /// Dismiss the alert
        /// </summary>
        /// <returns>awaitable task</returns>
        private static void Dismiss()
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
                    RetailSDK.WpfContentGridForUi.Children.Remove(_sInstance.MainGrid);
                    _sInstance.Popup.Child = _sInstance.MainGrid;
                }
                else
                {
                    _wpfOnWinForm.ElementHost.Child = null;
                    _sInstance.Popup.Child = _sInstance.MainGrid;
                    _wpfOnWinForm.Popup.Close();
                }
                _isShowing = false;
            });
        }

        private void ButtonClick(object sender, RoutedEventArgs e)
        {
            var b = (Button)sender;
            _sCurrent.Callback(_sCurrent, (int)b.Tag);
        }

        private static T XamlClone<T>(T original) where T : class
        {
            if (original == null)
                return null;

            object clone;
            using (var stream = new MemoryStream())
            {
                XamlWriter.Save(original, stream);
                stream.Seek(0, SeekOrigin.Begin);
                clone = XamlReader.Load(stream);
            }

            return clone as T;
        }
    }
}