using HidLibrary;
using Jint.Native;
using Jint.Native.Function;
using Jint.Native.Object;
using Jint.Runtime.Interop;
using Manticore;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace PayPalRetailSDK.JsObjects
{
    // TODO we can #ifdef our way around having separate files for Net4 and Desktop
    class MagtekUsbDevice : PayPalRetailObject
    {
        HidDevice device;
        List<FunctionInstance> jsCallbacks = new List<FunctionInstance>();
        bool isOpen = false;

        public MagtekUsbDevice(HidDevice device)
        {
            this.device = device;
            ObjectInstance callbacks = Engine.CreateJsObject();
            var isConnected = Engine.Wrap(new Func<bool>(() =>
            {
                return device.IsConnected && device.IsOpen;
            }));
            var connect = Engine.Wrap(new Func<JsValue, bool>((callback) =>
            {
                if (!device.IsOpen)
                {
                    jsCallbacks.Add(callback.As<FunctionInstance>());
                    device.OpenDevice();
                    device.MonitorDeviceEvents = true;
                    isOpen = true;
                    new Thread(new ThreadStart(ReceiveLoop)).Start();
                    NotifyCallbacks(JsValue.Undefined);
                }
                else
                {
                    // Call the callback right away?
                    callback.As<FunctionInstance>().Call(impl, ManticoreEngine.EmptyArgs);
                }
                return true;
            }));
            var send = Engine.Wrap(new Func<string, bool>((data) =>
            {
                return false;
            }));
            var disconnect = Engine.Wrap(new Func<bool>(() =>
            {
                if (device.IsOpen)
                {
                    isOpen = false;
                    device.CloseDevice();
                    return true;
                }
                return false;
            }));
            callbacks.FastAddProperty("isConnected", isConnected, false, true, true);
            callbacks.FastAddProperty("connect", connect, false, true, true);
            callbacks.FastAddProperty("disconnect", disconnect, false, true, true);
            callbacks.FastAddProperty("send", send, false, true, true);
            impl = PayPalRetailObject.CreateJSObject("MagtekRawUsbReaderDevice", new JsValue[] {
                device.DevicePath, callbacks
            });
            RetailSDK.jsSdk.DiscoveredPaymentDevice(new PaymentDevice(impl));
            // Tell the SDK this device is ready to go.
            RetailSDK.jsSdk.impl.Get("newDevice").As<FunctionInstance>().Call(RetailSDK.jsSdk.impl, new JsValue[] { impl });
        }

        private void ReceiveLoop()
        {
            while (true)
            {
                try
                {
                    HidReport report = device.ReadReport();
                    var buffer = report.GetBytes();
                    Engine.Js(() =>
                    {
                        impl.Get("received").As<FunctionInstance>().Call(impl, new JsValue[] { Convert.ToBase64String(buffer) });
                    });
                }
                catch (Exception)
                {
                    if (!isOpen)
                    {
                        return;
                    }
                }
            }
        }

        void NotifyCallbacks(JsValue error)
        {
            List<FunctionInstance> toNotify;
            lock (jsCallbacks)
            {
                toNotify = jsCallbacks;
                jsCallbacks = new List<FunctionInstance>();
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
                    catch (Exception) { }
                }
            }
        }
    }
}
