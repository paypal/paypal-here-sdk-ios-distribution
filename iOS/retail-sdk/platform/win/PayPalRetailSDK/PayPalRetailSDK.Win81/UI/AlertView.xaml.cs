using System;
using System.Collections.Generic;
using System.Threading.Tasks;
#if NETFX_CORE
using Windows.ApplicationModel.Core;
using Windows.Foundation;
using Windows.UI.Core;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
#else
using System.Windows;
using System.Windows.Controls;
#endif

// The User Control item template is documented at http://go.microsoft.com/fwlink/?LinkId=234236
namespace PayPalRetailSDK.UI
{
    /// <summary>
    /// Alert view for WinPhone/WinRT
    /// reference: http://stackoverflow.com/questions/11593978/in-winrt-api-how-to-accept-user-input-in-a-dialog-just-like-in-weather-and-fina
    /// </summary>
    public sealed partial class AlertView : UserControl
    {
        /// <summary>
        /// The AlertViewHandle protects against out-of-turn calls to the exposed capabilities of the singleton
        /// </summary>
        public class AlertViewHandle
        {
            private int Counter;
            internal AlertViewDelegate Callback;

            public AlertViewHandle(int counter, AlertViewDelegate callback)
            {
                Counter = counter;
                Callback = callback;
            }
            public void Dismiss()
            {
                if (Counter == AlertView.sShowCount)
                {
                    AlertView.Dismiss();
                }
            }
            public void SetTitle(String title)
            {
                if (Counter == AlertView.sShowCount)
                {
                    AlertView.SetTitle(title);
                }
            }
            public void SetMessage(String message)
            {
                if (Counter == AlertView.sShowCount)
                {
                    AlertView.SetMessage(message);
                }
            }
        }

        public delegate void AlertViewDelegate(AlertViewHandle alertView, int selectedButton);

        private AlertView()
        {
            this.InitializeComponent();
        }

        private static object locker = new object();
        private static AlertView sInstance;
        private static AlertViewHandle sCurrent;
        private static int sShowCount;

        public static AlertView GetInstance()
        {
            lock (locker)
            {
                if (sInstance == null)
                {
                    sInstance = new AlertView();
                }
            }
            return sInstance;
        }

        // Make sure you call this from the UI thread
        public static AlertViewHandle Show(String title, String message, bool showActivity, String cancel, List<String> otherButtons, AlertViewDelegate callback)
        {
            AlertViewHandle handle = new AlertViewHandle(++sShowCount, callback);

            var alert = GetInstance();
            alert.mTitle.Text = title ?? String.Empty;
            alert.mMessage.Text = message ?? String.Empty;
            alert.mCancel.Content = cancel ?? String.Empty;
            alert.mCancel.Tag = 0;
            alert.mCancel.Visibility = String.IsNullOrEmpty(cancel) ? Visibility.Collapsed : Visibility.Visible;
            alert.mProgress.Visibility = showActivity ? Visibility.Visible : Visibility.Collapsed;
            alert.mButtonPanel.Children.Clear();
            if (otherButtons != null && otherButtons.Count > 0)
            {
                int tag = 0;
                foreach (var buttonName in otherButtons)
                {
                    Button b = new Button();
                    b.Content = buttonName;
                    b.Tag = tag++;
                    b.Click += alert.ButtonClick;
                    alert.mButtonPanel.Children.Add(b);
                }
                alert.mCancel.Tag = tag;
            }
            alert.InitSize();
            sCurrent = handle;
#if NETFX_CORE
            if (!alert.mPopup.IsOpen)
            {
                alert.mPopup.IsOpen = true;
            }
#else
            // TODO This whole thing is kind of broken in WPF/WinXP78 because the "popup" is not on the main window.
            if (alert.mPopup.Child != null)
            {
                var window = Application.Current.MainWindow;
                alert.mPopup.Child = null;
                ((Grid)window.Content).Children.Add(alert.mMainGrid);
            }
#endif
            return handle;
        }

        /// <summary>
        /// Set the height/width to fit the screen
        /// Do not invoke directly, call this from a UI Dispatcher
        /// </summary>
        private void InitSize()
        {
            //ToDo: Make sure this resizes when the app is resized (e.g. on tablets or rotation)
#if NETFX_CORE
            mOverlay.Height = Window.Current.Bounds.Height;
            mOverlay.Width = Window.Current.Bounds.Width;
            mContent.Width = Window.Current.Bounds.Width;
#else
            var window = Application.Current.MainWindow;
            mOverlay.Height = window.ActualHeight;
            mOverlay.Width = mContent.Width = window.ActualWidth;
#endif
        }

        /// <summary>
        /// Set the title of the alert on the UI Dispatcher
        /// </summary>
        /// <param name="value">Title to be displayed</param>
        private static void SetTitle(string value)
        {
            var task = RetailSDK.RunOnUIThreadAsync(() =>
            {
                GetInstance().mTitle.Text = value;
            });
        }

        /// <summary>
        /// Set the message on the alert
        /// </summary>
        /// <param name="value">Message to be displayed</param>
        private static void SetMessage(string value)
        {
            var task = RetailSDK.RunOnUIThreadAsync(() =>
            {
                GetInstance().mMessage.Text = value;
            });
        }

        /// <summary>
        /// Dismiss the alert
        /// </summary>
        /// <returns>awaitable task</returns>
        private static void Dismiss()
        {
            var task = RetailSDK.RunOnUIThreadAsync(() =>
            {
                //We are not using GetInstance here because we do not want to create an instance if we do not already have one
                if (sInstance != null)
                {
#if NETFX_CORE
                    if (sInstance.mPopup.IsOpen)
                    {
                        sInstance.mPopup.IsOpen = false;
                        sInstance = null;
                    }
#else
                    if (sInstance.mPopup.Child == null)
                    {
                        // TODO yeah, this may not be a grid, might be WinForms, etc... Need a better strategy for injecting/unjecting the control
                        Grid g = (Grid)Application.Current.MainWindow.Content;
                        g.Children.Remove(sInstance.mMainGrid);
                        sInstance.mPopup.Child = sInstance.mMainGrid;
                    }
#endif
                }
            });
        }

        private void ButtonClick(object sender, RoutedEventArgs e)
        {
            Button b = (Button)sender;
            sCurrent.Callback(sCurrent, (int)b.Tag);
        }
    }
}