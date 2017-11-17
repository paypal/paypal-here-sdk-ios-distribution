using HidLibrary;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PayPalRetailSDK.JsObjects
{
    class MagtekUsbDevice : PayPalRetailObject
    {
        HidDevice device;
        List<object> jsCallbacks = new List<object>();
        bool isOpen = false;

        public MagtekUsbDevice(HidDevice device)
        {
            this.device = device;
            dynamic callbacks = RetailSDK.jsSdk.impl.make();
            callbacks.isConnected = new Func<bool>(() =>
            {
                return device.IsConnected && device.IsOpen;
            });
            callbacks.connect = new Func<dynamic, bool>((callback) =>
            {
                if (!device.IsOpen)
                {
                    jsCallbacks.Add(callback);
                    device.OpenDevice();
                    device.MonitorDeviceEvents = true;
                    isOpen = true;
                    ReceiveLoop();
                    notifyConnectionAttempt(null);
                }
                else
                {
                    // Call the callback right away?
                    callback(null);
                }
                return true;
            });
            callbacks.send = new Func<string, bool>((data) =>
            {
                return false;
            });
            callbacks.disconnect = new Func<bool>(() => {
                if (device.IsOpen) {
                    isOpen = false;
                    device.CloseDevice();
                    return true;
                }
                return false;
            });
            Engine.Js(() =>
            {
                impl = Engine.CreateJsObject("MagtekRawUsbReaderDevice",  Engine.Array(device.DevicePath, callbacks));
                RetailSDK.jsSdk.DiscoveredPaymentDevice(new PaymentDevice(impl));
            });
        }

        private async void ReceiveLoop()
        {
            while (true)
            {
                try
                {
                    HidReport report = await device.ReadReportAsync();
                    var buffer = report.GetBytes();
                    Engine.Js(() =>
                    {
                        this.impl.received(Convert.ToBase64String(buffer));
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

        private void notifyConnectionAttempt(object error)
        {
            List<object> snapshot = jsCallbacks;
            jsCallbacks = new List<object>();
            foreach (dynamic cb in snapshot)
            {
                try
                {
                    cb(error);
                }
                catch (Exception cbException)
                {
                    PayPalRetailObject.Native.log(null, "paymentDevice", "Exception calling callback: " + cbException.ToString());
                }
            }
        }
    }
}
