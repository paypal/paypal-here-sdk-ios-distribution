using Jint;
using Jint.Native;
using Jint.Native.Function;
using Jint.Native.Object;
using Jint.Runtime.Interop;
using PayPalRetailSDK.JsObjects;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Windows.Threading;
using Application = System.Windows.Application;

///////////////////////////////////////

namespace PayPalRetailSDK
{
    public class RetailSDK
    {
        internal static SDK jsSdk;
        internal static DeviceManager deviceManager;
        private const string LoggingComponentName = "native.retailSdk";

        /// <summary>
        /// Set 
        /// </summary>
        internal static Form WinFormAlertParent { get; private set; }

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
            if (!IsWpfApp && WinFormAlertParent == null)
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
            deviceManager = new DeviceManager();

            try
            {
                PayPalRetailObject.CreateJsEngine(javascript);
            }
            catch (Exception x)
            {
                System.Windows.MessageBox.Show("Please make sure https://support.microsoft.com/en-us/kb/2468871 is installed!\n\n" + x.ToString());
                return false;
            }

            jsSdk.SetExecutingEnvironment(Environment.MachineName,
                string.Format("{0}.{1}", Environment.OSVersion, "net40"), Assembly.GetExecutingAssembly().GetName().Name);
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

                jsSdk.Shutdown();
            }
            catch (Exception)
            {
                //We are shutting down, so cannot do much here.
            }
        }

        /// <summary>
        /// Tear down any resources used by the SDK. After calling this, Initialize AND InitializeMerchant
        /// would need to be called again to use the SDK
        /// </summary>
        public static void Shutdown()
        {
            deviceManager.StopWatching();
            deviceManager = null;
            jsSdk = null;
            PayPalRetailObject.Engine.Shutdown();
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
        /// <param name="token">The token received from your backend server or authentication source.</param>
        /// <returns>A task which you can await/Wait() on to be notified when we are ready to proceed.
        /// If initialization fails, a RetailSDK exception will be thrown from await/Wait()</returns>
        public static Task<Merchant> InitializeMerchant(string token)
        {
            var callbackCompletion = new TaskCompletionSource<Merchant>();
            var callback = PayPalRetailObject.Engine.Wrap(new Action<JsValue, JsValue>((cbError, merchant) =>
            {
                if (cbError.IsObject())
                {
                    callbackCompletion.SetException(new RetailSDKException(cbError.AsObject()));
                }
                else
                {
                    callbackCompletion.SetResult(new Merchant(merchant.AsObject()));
                }
            }));
            Engine.Js(new Action(() =>
            {
                jsSdk.impl.Get("initializeMerchant").As<FunctionInstance>().Call(jsSdk.impl, new JsValue[] {
                    new JsValue(token),
                    callback
                });
            }));
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

        internal static void ready(ObjectInstance sdk)
        {
            jsSdk = new SDK(sdk);
            deviceManager.StartWatching();
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

        internal static Manticore.ManticoreEngine Engine
        {
            get
            {
                return PayPalRetailObject.Engine;
            }
        }

        internal static void RunOnUiThread(Action action)
        {
            if (IsWpfApp)
            {
                Application.Current.Dispatcher.Invoke(new Action(() =>
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
                WinFormAlertParent.Invoke(new Action(() =>
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
