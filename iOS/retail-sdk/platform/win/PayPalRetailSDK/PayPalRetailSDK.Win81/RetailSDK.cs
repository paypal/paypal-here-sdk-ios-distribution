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
using System.Threading;
using System.Threading.Tasks;
using Windows.ApplicationModel.Core;
using Windows.Foundation;
using Windows.UI.Core;

namespace PayPalRetailSDK
{
    public class RetailSDK
    {
        internal static ObjectInstance jsSdk;
        internal static DeviceManager deviceManager;

        /// <summary>
        /// This should be the first call you make in the SDK. Typically, this occurs in your Main Window constructor,
        /// but if you want to delay loading the Retail SDK until you know it's needed, you can locate it accordingly.
        /// </summary>
        /// <returns></returns>
        public static bool Initialize()
        {
            if (PayPalRetailObject.Engine != null && PayPalRetailObject.Engine.IsStarted)
            {
                return true;
            }

            String javascript;
            using (Stream s = typeof(RetailSDK).GetTypeInfo().Assembly.GetManifestResourceStream("PayPalRetailSDK.Resources.PayPalRetailSDK.js"))
            {
                using (StreamReader reader = new StreamReader(s))
                {
                    javascript = reader.ReadToEnd();
                }
            }
            deviceManager = new DeviceManager();

            PayPalRetailObject.CreateJsEngine(javascript);
            return true;
        }

        private static readonly Destructor Finalise = new Destructor();

        private sealed class Destructor
        {
            ~Destructor()
            {
                // One time only destructor.
                try
                {
                    RetailSDK.Shutdown();
                }
                catch
                {
                    //we are shutting down, cannot do much here.
                }                
            }
        }

        internal static Manticore.ManticoreEngine Engine
        {
            get
            {
                return PayPalRetailObject.Engine;
            }
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
            var callback = PayPalRetailObject.Engine.Wrap(new Action<JsValue,JsValue>((cbError,merchant) =>
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
            Engine.Js(() =>
            {
                jsSdk.Get("initializeMerchant").As<FunctionInstance>().Call(jsSdk, new JsValue[] {
                    new JsValue(token),
                    callback
                });
            });
            return callbackCompletion.Task;
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
            jsSdk = null;
            if (PayPalRetailObject.Engine != null)
            {
                PayPalRetailObject.Engine.Shutdown();
            }
        }

        /// <summary>
        /// This is the primary starting point for taking a payment. First create an invoice, then create a transaction, then
        /// begin the transaction to have the SDK listen for events that will go through the relevant flows for a payment type.
        /// </summary>
        /// <param name="invoice"></param>
        /// <returns></returns>
        public static TransactionContext CreateTransaction(Invoice invoice)
        {
            return Engine.JsWithReturn(() =>
            {
                return new TransactionContext(jsSdk.Get("createTransaction").As<FunctionInstance>().Call(jsSdk, new JsValue[] { invoice.impl }).AsObject());
            });
        }

        internal static void ready(ObjectInstance sdk)
        {
            jsSdk = sdk;
            deviceManager.StartWatching();
        }

        private static CoreDispatcher UIDispatcher
        {
            get
            {
                CoreDispatcher dispatcher;
                try
                {
                    dispatcher = CoreApplication.MainView.CoreWindow.Dispatcher;
                }
                catch (Exception)
                {
                    try
                    {
                        // This can throw if we're shutting down the app.
                        dispatcher = CoreApplication.MainView.Dispatcher;
                    }
                    catch (Exception)
                    {
                        return null;
                    }
                }
                return dispatcher;
            }
        }

        internal static void LogViaJs(String level, String component, String message)
        {
            Engine.Js(() =>
            {
                jsSdk.Get("logViaJs").As<FunctionInstance>().Call(jsSdk, new JsValue[] {
                    level,
                    component,
                    message
                });
            });
        }

        internal static IAsyncAction RunAsync(DispatchedHandler agileCallback)
        {
            return UIDispatcher.RunAsync(CoreDispatcherPriority.Normal, agileCallback);
        }

        internal static async Task RunOnUIThreadAsync(DispatchedHandler agileCallback)
        {
            if (UIDispatcher.HasThreadAccess)
            {
                agileCallback();
            }
            else
            {
                await UIDispatcher.RunAsync(CoreDispatcherPriority.Normal, () => agileCallback());
            }
        }
    }
}
