using PayPalRetailSDK;
using System;
using System.Reflection;
using System.Collections.Generic;
using System.IO;
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

// The Blank Page item template is documented at http://go.microsoft.com/fwlink/?LinkId=234238

namespace RetailSDKTestApp.WinRT
{
    /// <summary>
    /// An empty page that can be used on its own or navigated to within a Frame.
    /// </summary>
    public sealed partial class MainPage : Page
    {
        bool sdkIsReady = false;

        public MainPage()
        {            
            this.InitializeComponent();
            RetailSDK.Initialize();
            var task = RetailSDK.InitializeMerchant(new StreamReader(typeof(MainPage).GetTypeInfo().Assembly.GetManifestResourceStream("RetailSDKTestApp.WinRT.testToken.txt")).ReadToEnd());
            task.ContinueWith((merchant) =>
            {
                sdkIsReady = merchant != null;
            });
        }

        private void Button_Click(object sender, RoutedEventArgs e)
        {
            var amount = this.amountField.Text;
            Invoice newInvoice = new Invoice(null);
            newInvoice.AddItem("Amount", decimal.One, decimal.Parse(amount), "Item1", null);
            var txManager = PayPalRetailSDK.RetailSDK.CreateTransaction(newInvoice);
            txManager.Completed += txManager_Completed;
            txManager.Begin(true);
        }

        void txManager_Completed(TransactionContext sender, RetailSDKException error, TransactionRecord record)
        {
        }


    }
}
