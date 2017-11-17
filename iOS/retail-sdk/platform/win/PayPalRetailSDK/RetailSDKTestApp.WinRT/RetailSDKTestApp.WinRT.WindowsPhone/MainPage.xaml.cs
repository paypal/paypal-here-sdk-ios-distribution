using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Linq;
using System.Runtime.InteropServices.WindowsRuntime;
using Windows.Foundation;
using Windows.Foundation.Collections;
using Windows.UI.Xaml;
using Windows.UI.Xaml.Controls;
using Windows.UI.Xaml.Controls.Primitives;
using Windows.UI.Xaml.Data;
using Windows.UI.Xaml.Input;
using Windows.UI.Xaml.Media;
using Windows.UI.Xaml.Navigation;
using PayPalRetailSDK;
using Windows.UI.Core;

// The Blank Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=234238

namespace RetailSDKTestApp.WinRT
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Page
    {
        TransactionContext context;

        public MainPage()
        {
            this.InitializeComponent();

            this.NavigationCacheMode = NavigationCacheMode.Required;
            chargeButton.IsEnabled = false;
            PayPalRetailSDK.RetailSDK.Initialize();
            messageTextBlock.Text = "SDK Initialized.";
            var token = new StreamReader(typeof(MainPage).GetTypeInfo().Assembly.GetManifestResourceStream("RetailSDKTestApp.WinRT.testToken.txt")).ReadToEnd();
            InitializeMerchant(token);
        }

        private async void InitializeMerchant(string token)
        {
            try
            {
                messageTextBlock.Text = "Initializing Merchant...";
                var merchant = await PayPalRetailSDK.RetailSDK.InitializeMerchant(token);
                await this.Dispatcher.RunAsync(Dispatcher.CurrentPriority, () =>
                {
                    chargeButton.IsEnabled = true;
                    messageTextBlock.Text = "Merchant initialized: " + merchant.EmailAddress;
                });
            }
            catch (Exception x)
            {
                var asyncer = this.Dispatcher.RunAsync(Dispatcher.CurrentPriority, () =>
                {
                    messageTextBlock.Text = "Merchant init failed: " + x.ToString();
                });
            }
        }

        /// <summary>
        /// Invoked when this page is about to be displayed in a Frame.
        /// </summary>
        /// <param name="e">Event data that describes how this page was reached.
        /// This parameter is typically used to configure the page.</param>
        protected override void OnNavigatedTo(NavigationEventArgs e)
        {
            // TODO: Prepare page for display here.

            // TODO: If your application contains multiple pages, ensure that you are
            // handling the hardware Back button by registering for the
            // Windows.Phone.UI.Input.HardwareButtons.BackPressed event.
            // If you are using the NavigationHelper provided by some templates,
            // this event is handled for you.
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            var amount = this.amountField.Text;
            Invoice newInvoice = new Invoice(null);
            newInvoice.AddItem("Amount", decimal.One, decimal.Parse(amount), "Item1", null);
            context = PayPalRetailSDK.RetailSDK.CreateTransaction(newInvoice);
            messageTextBlock.Text = "Created Transaction Context";
            context.Completed += context_Completed;
            context.Begin(true);
            amountField.IsReadOnly = true;
            chargeButton.IsEnabled = false;
        }

        void context_Completed(TransactionContext sender, RetailSDKException error, TransactionRecord record)
        {
            var fireAndForgetAgain = this.Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
            {
                chargeButton.IsEnabled = true;
                amountField.IsReadOnly = false;
                messageTextBlock.Text = "Transaction Completed " + (error != null ? error.ToString() : record.TransactionNumber);
            });
        }

    }
}
