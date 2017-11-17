using Microsoft.ClearScript.V8;
using PayPalRetailSDK.JsObjects;
using System;
using System.Dynamic;
using System.IO;
using System.Reflection;
using System.Runtime.Remoting.Channels;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Windows.Controls;
using System.Windows.Forms;
using System.Windows.Threading;
using Application = System.Windows.Application;

/**
 * WINDOWS DESKTOP (non-RT) VERSION
 **/
namespace PayPalRetailSDK
{
    public sealed class RetailSDK
    {
        internal static SDK jsSdk;
        internal static DeviceScanner deviceManager;
        private const string LoggingComponentName = "native.retailSdk";
        private static Grid _wpfContentControlForAlertDialogs;

        /// <summary>
        /// Set 
        /// </summary>
        internal static Form WinFormAlertParent { get; private set; }

        /// <summary>
        /// Content control to which the SDK UI would be displayed
        /// </summary>
        public static Grid WpfContentGridForUi
        {
            get { return _wpfContentControlForAlertDialogs ?? (Grid) Application.Current.MainWindow.Content; }
            set { _wpfContentControlForAlertDialogs = value; }
        }

        internal static bool Initialize(bool isTest, Form sdkAlertParentForWinForms = null)
        {
            AppDomain.CurrentDomain.UnhandledException += (sender, e) =>
            {
                try
                {
                    Console.Out.WriteLine($"Unhandled exception {e.ExceptionObject.ToString()}");
                    LogViaJs("error", "native.unhandledException", e.ExceptionObject.ToString());
                }
                catch (Exception)
                {
                    // ignored
                }
            };

            if (PayPalRetailObject.Engine != null && PayPalRetailObject.Engine.IsStarted)
            {
                return true;
            }

            WinFormAlertParent = sdkAlertParentForWinForms;
            if (!isTest && !IsWpfApp && WinFormAlertParent == null)
            {
                throw new Exception("Please set the parent form for UI alerts using WinFormAlertParent argument");
            }

            if (Application.Current != null)
            {
                Application.Current.Exit += ApplicationExit;
            }
            else
            {
                System.Windows.Forms.Application.ApplicationExit += ApplicationExit;
            }

            String javascript;
            using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("PayPalRetailSDK.Resources.PayPalRetailSDK.js"))
            {
                using (StreamReader reader = new StreamReader(s))
                {
                    javascript = reader.ReadToEnd();
                }
            }
            deviceManager = new DeviceScanner();

            PayPalRetailObject.CreateJsEngine(javascript);
            jsSdk.SetExecutingEnvironment(Environment.MachineName,
                string.Format("{0}.{1}", Environment.OSVersion, "net45"), Assembly.GetExecutingAssembly().GetName().Name);
            return true;
        }

        private static void ApplicationExit(object sender, EventArgs e)
        {
            try
            {
                //remove exit handlers
                if (Application.Current != null)
                {
                    Application.Current.Exit -= ApplicationExit;
                }
                else
                {
                    System.Windows.Forms.Application.ApplicationExit -= ApplicationExit;
                }

                jsSdk.Logout();
            }
            catch (Exception)
            {
                //We are shutting down, so cannot do much here.
            }
        }

        /// <summary>
        /// This should be the first call you make in the SDK. Typically, this occurs in your Main Window constructor,
        /// but if you want to delay loading the Retail SDK until you know it's needed, you can locate it accordingly.
        /// </summary>
        /// <param name="sdkAlertParentForWinForms">
        /// ONLY REQUIRED WHEN FOR A WINDOWS FORM APP. The Parent form to which the UI elements (like Signature form, Receipt form, etc.) would be attached.
        /// </param>
        /// <returns></returns>
        public static bool Initialize(Form sdkAlertParentForWinForms = null)
        {
            return Initialize(false, sdkAlertParentForWinForms);
        }

        /// <summary>
        /// Tear down any resources used by the SDK. After calling this, Initialize AND InitializeMerchant
        /// would need to be called again to use the SDK
        /// </summary>
        public static void Shutdown()
        {
            if (deviceManager != null)
            {
                deviceManager.StopWatching();
            }
            deviceManager = null;
            if (PayPalRetailObject.Engine != null)
            {
                PayPalRetailObject.Engine.Shutdown();
            }
            jsSdk = null;

        }

        /// <summary>
        /// A PaymentDevice has been discovered. For further events, such as device readiness, removal or the need for a software upgrade, your application 
        /// should subscribe to the relevant events on the device parameter. Please note that this doesn't always mean the device is present. In certain 
        /// cases (e.g. Bluetooth) we may know about the device independently of whether it's currently connected or available.
        /// </summary>
        public static event SDK.DeviceDiscoveredDelegate DeviceDiscovered
        {
            add
            {
                if (jsSdk == null)
                {
                    throw new InvalidOperationException("SDK Not initialized");
                }
                jsSdk.DeviceDiscovered += value;
            }
            remove
            {
                if (jsSdk == null)
                {
                    throw new InvalidOperationException("SDK Not initialized");
                }
                jsSdk.DeviceDiscovered -= value;
            }
        }

        /// <summary>
        /// Once you have retrieved a token for your merchant (typically from a backend server), call
        /// InitializeMerchant and wait for the task to complete before doing more SDK operations.
        /// </summary>
        /// <param name="credentials">The object containing the token you received from the backend</param>
        /// <returns>
        /// A task which you can await/Wait() on to be notified when we are ready to proceed.
        /// If initialization fails, a RetailSDK exception will be thrown from await/Wait()
        /// </returns>
        public static Task<Merchant> InitializeMerchant(SdkCredentials credentials)
        {
            dynamic tokenObj = PayPalRetailObject.Engine.ManticoreJsObject._.construct();
            tokenObj.accessToken = credentials.AccessToken;
            tokenObj.refreshUrl = credentials.RefreshUrl;
            tokenObj.refreshToken = credentials.RefreshToken;
            tokenObj.appId = credentials.ClientId;
            tokenObj.appSecret = credentials.ClientSecret;
            tokenObj.environment = credentials.Environment;
            string token = jsSdk.impl.buildCompositeToken(tokenObj);
            return InitializeMerchant(token);
        }

        /// <summary>
        /// Logout must be invoked on exiting the Application/logging off the merchant. This clears the state
        /// of the SDK
        /// </summary>
        public static void Logout()
        {
            deviceManager.StopWatching();
            jsSdk.impl.logout();
        }

        /// <summary>
        /// Beging card reader discovery loop that keeps scanning for paired devices periodically. RetailSDK.DeviceDiscovered event will be emitted if a known card reader is discovered
        /// </summary>
        public static void BeginCardReaderDiscovery()
        {
            deviceManager.StartWatching();
        }

        /// <summary>
        /// End card reader discover loop
        /// </summary>
        public static void EndCardReaderDiscovery()
        {
            deviceManager.StopWatching();
        }

        /// <summary>
        /// Once you have retrieved a token for your merchant (typically from a backend server), call
        /// InitializeMerchant and wait for the task to complete before doing more SDK operations.
        /// </summary>
        /// <param name="token">The token received from your backend server or authentication source.</param>
        /// <returns>A task which you can await/Wait() on to be notified when we are ready to proceed.
        /// If initialization fails, a RetailSDK exception will be thrown from await/Wait()</returns>
        private static Task<Merchant> InitializeMerchant(string token)
        {
            var callbackCompletion = new TaskCompletionSource<Merchant>();
            var callback = new Action<dynamic,dynamic>((cbError, merchant) =>
            {
                if (!PayPalRetailObject.Engine.IsNullOrUndefined(cbError))
                {
                    callbackCompletion.SetException(new RetailSDKException(cbError));
                }
                else
                {
                    callbackCompletion.SetResult(new Merchant(merchant));
                }
            });
            try
            {
                jsSdk.impl.initializeMerchant(token, "production", callback);
            }
            catch (Exception ex)
            {
                callbackCompletion.SetException(new RetailSDKException(ex));
            }
            return callbackCompletion.Task;
        }

        /// <summary>
        /// This is the primary starting point for taking a payment. First create an invoice, then create a transaction, then
        /// begin the transaction to have the SDK listen for events that will go through the relevant flows for a payment type.
        /// </summary>
        /// <param name="invoice"></param>
        /// <returns></returns>
        public static TransactionContext CreateTransaction(Invoice invoice)
        {
            return jsSdk.CreateTransaction(invoice);
        }

        internal static IRetailNetworkRequestHandler NetworkHandler;

        /// <summary>
        /// If you have a need to route our HTTP traffic through your own proxies or network layers, implement
        /// the IRetailNetworkRequestHandler interface and then call this method with an instance of your 
        /// implementation.
        /// </summary>
        public static void SetNetworkHandler(IRetailNetworkRequestHandler handler)
        {
            NetworkHandler = handler;
        }

        internal static void ready(dynamic sdk)
        {
            jsSdk = new SDK(sdk);
        }

        internal static void LogViaJs(String level, String component, String message)
        {
            if (jsSdk == null)
            {
                return;
            }

            try
            {
                jsSdk.LogViaJs(level, component, message, null);
            }
            catch (Exception)
            {
                // Don't crash just because logging failed.
            }
        }

        internal static void RunOnUIThreadAsync(Action action)
        {
            if (IsWpfApp)
            {
                Application.Current.Dispatcher.BeginInvoke(new Action(() =>
                {
                    try
                    {
                        action();
                    }
                    catch (Exception ex)
                    {
                        LogViaJs("error", LoggingComponentName, ex.ToString());
                        throw;
                    }
                }));
            }
            else
            {
                WinFormAlertParent.BeginInvoke(new Action(() =>
                {
                    try
                    {
                        action();
                    }
                    catch (Exception ex)
                    {
                        LogViaJs("error", LoggingComponentName, ex.ToString());
                        throw;
                    }
                }));
            }
        }

        internal static bool IsWpfApp
        {
            get { return Application.Current != null; }
        }

    }
}
