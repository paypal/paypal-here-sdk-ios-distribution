using Jint.Native;
using Jint.Native.Function;
using Jint.Native.Object;
using Jint.Runtime.Interop;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.ApplicationModel.Core;
using Windows.Devices.Enumeration;
using Windows.Devices.PointOfService;
using Windows.UI.Core;
using System.Runtime.InteropServices.WindowsRuntime;

namespace PayPalRetailSDK.JsObjects
{
    class WindowsMagneticCardReader : PaymentDevice
    {
        DeviceInformation device;
        MagneticStripeReader unclaimedReader;
        ClaimedMagneticStripeReader claimedReader;
        List<FunctionInstance> callbacks = new List<FunctionInstance>();
        bool didSetSerial = false;

        public WindowsMagneticCardReader(DeviceInformation device) : base(null)
        {
            this.device = device;
            ObjectInstance callbacks = PayPalRetailObject.Engine.CreateJsObject();

            DelegateWrapper isConnected = PayPalRetailObject.Engine.Wrap(new Func<bool>(() =>
            {
                return claimedReader != null;
            }));
            DelegateWrapper connect = PayPalRetailObject.Engine.Wrap(new Action<JsValue>((jsCallback) =>
            {
                var connectTask = CoreApplication.MainView.CoreWindow.Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
                {
                    this.Connect(jsCallback);
                });
            }));
            DelegateWrapper send = PayPalRetailObject.Engine.Wrap(new Func<JsValue, bool>((data) =>
            {
                // Nothing to send at the moment
                return false;
            }));
            DelegateWrapper disconnect = PayPalRetailObject.Engine.Wrap(new Action(() =>
            {
                this.Disconnect();
            }));
            callbacks.FastAddProperty("isConnected", isConnected, false, true, true);
            callbacks.FastAddProperty("connect", connect, false, true, true);
            callbacks.FastAddProperty("disconnect", disconnect, false, true, true);
            callbacks.FastAddProperty("send", send, false, true, true);
            impl = PayPalRetailObject.Engine.CreateJsObject("MagneticReaderDevice", new JsValue[] {
    	        new JsValue(device.Name),
		        callbacks
    		});
            Engine.Js(() =>
            {
                // TODO figure out a better way to really set the manufacturer
                impl.Put("manufacturer", "Magtek", true);
                // Tell the SDK this device is ready to go.
                RetailSDK.jsSdk.Get("newDevice").As<FunctionInstance>().Call(RetailSDK.jsSdk, new JsValue[] { impl });
            });
        }

        public async void Connect(JsValue callback)
        {
            lock (callbacks)
            {
                callbacks.Add(callback.As<FunctionInstance>());
            }
            // TODO protect against overlapping connection attempts? (or make JS guarantee not to do that)
            if (unclaimedReader == null)
            {
                unclaimedReader = await MagneticStripeReader.FromIdAsync(device.Id);
                if (unclaimedReader == null)
                {
                    NotifyCallbacks(PayPalRetailObject.Engine.jsEngine.Error.Construct(new JsValue[] {
                        new JsValue("DEVICE_UNAVAILABLE")
                    }));
                    return;
                }
                var readerType = unclaimedReader.Capabilities.CardAuthentication.ToString();
                var setManufacturer = impl.Get("setReaderInformation").As<FunctionInstance>();
                if (setManufacturer != null)
                {
                    setManufacturer.Call(impl, new JsValue[] { new JsValue("readerType") });
                }
            }
            claimedReader = await unclaimedReader.ClaimReaderAsync();
            if (claimedReader == null)
            {
                // TODO put a shortcut to make an error on engine...
                NotifyCallbacks(Engine.jsEngine.Error.Construct(new JsValue[] {
                        new JsValue("DEVICE_UNAVAILABLE")
                    }));
                return;
            }
            claimedReader.IsDecodeDataEnabled = true;
            claimedReader.BankCardDataReceived += BankCardDataReceived;
            claimedReader.ErrorOccurred += ErrorOccurred;
            claimedReader.VendorSpecificDataReceived += VendorSpecificDataReceived;
            await claimedReader.EnableAsync();
            NotifyCallbacks(JsValue.Undefined);
        }

        private void VendorSpecificDataReceived(ClaimedMagneticStripeReader sender, MagneticStripeReaderVendorSpecificCardDataReceivedEventArgs args)
        {
        }

        void ErrorOccurred(ClaimedMagneticStripeReader sender, MagneticStripeReaderErrorOccurredEventArgs args)
        {
            ObjectInstance cardInfo = PayPalRetailObject.Engine.CreateJsObject();
            cardInfo.Put("event", new JsValue("failed"), true);
            Engine.Js(() =>
            {
                this.impl.Get("received").As<FunctionInstance>().Call(this.impl, new JsValue[] { cardInfo });
            });
        }

        void BankCardDataReceived(ClaimedMagneticStripeReader sender, MagneticStripeReaderBankCardDataReceivedEventArgs args)
        {
            var cardInfo = new MagneticCard
            {
                Reader = this,
                FormFactor = PaymentDeviceFormFactor.MagneticCardSwipe,
                Pan = args.AccountNumber,
                Expiration = args.ExpirationDate,
                FirstName = args.FirstName,
                LastName = args.Surname
            };

            if (!string.IsNullOrEmpty(args.MiddleInitial))
            {
                cardInfo.MiddleInitial = args.MiddleInitial;
            }
            if (!string.IsNullOrEmpty(args.Suffix))
            {
                cardInfo.impl.FastAddProperty("suffix", new JsValue(args.Suffix), false, true, false);
            }
            cardInfo.impl.FastAddProperty("service", new JsValue(args.ServiceCode), false, true, false);
            if (args.Report.AdditionalSecurityInformation != null)
            {
                var ksn = BitConverter.ToString(args.Report.AdditionalSecurityInformation.ToArray()).Replace("-", "");
                cardInfo.Ksn = ksn;
                if (!didSetSerial)
                {
                    // TODO we need to know it's magtek somehow
                    Engine.Js(() =>
                    {
                        impl.Put("serialNumber", ksn.Substring(0, 14), true);
                    });
                    didSetSerial = true;
                }
            }
            if (args.Report.Track1 != null && args.Report.Track1.EncryptedData != null)
            {
                cardInfo.Track1 = BitConverter.ToString(args.Report.Track1.EncryptedData.ToArray()).Replace("-", "");
            }
            if (args.Report.Track2 != null && args.Report.Track2.EncryptedData != null)
            {
                cardInfo.Track2 = BitConverter.ToString(args.Report.Track2.EncryptedData.ToArray()).Replace("-", "");
            }
            if (args.Report.Track3 != null && args.Report.Track3.EncryptedData != null)
            {
                cardInfo.Track3 = BitConverter.ToString(args.Report.Track3.EncryptedData.ToArray()).Replace("-", "");
            }
            if (args.Report.CardAuthenticationData != null)
            {
                cardInfo.impl.FastAddProperty("cardAuth", new JsValue(BitConverter.ToString(args.Report.CardAuthenticationData.ToArray()).Replace("-", "")), false, true, false);
            }
            Engine.Js(() =>
            {
                var fn = this.impl.Get("received").As<ScriptFunctionInstance>();
                fn.Call(this.impl, new JsValue[] { cardInfo.impl });
            });
        }

        public async void Disconnect()
        {
            if (claimedReader != null)
            {
                await claimedReader.DisableAsync();
                claimedReader.Dispose();
                claimedReader = null;
            }
        }

        void NotifyCallbacks(JsValue error)
        {
            List<FunctionInstance> toNotify;
            lock (callbacks)
            {
                toNotify = callbacks;
                callbacks = new List<FunctionInstance>();
            }
            foreach (FunctionInstance fi in toNotify)
            {
                if (fi != null)
                {
                    try
                    {
                        Engine.Js(() =>
                        {
                            fi.Call(JsValue.Null, new JsValue[] { error });
                        });
                    }
                    catch (Exception x)
                    {
                        RetailSDK.LogViaJs("error", "native.device.mag", x.ToString());
                    }
                }
            }
        }
    }
}
