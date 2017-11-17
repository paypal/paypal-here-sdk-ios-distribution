using Jint.Native;
using Jint.Native.Function;
using Jint.Native.Object;
using Jint.Runtime;
using Jint.Runtime.Interop;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using Windows.ApplicationModel.Core;
using Windows.Devices.Bluetooth.Rfcomm;
using Windows.Devices.Enumeration;
using Windows.Networking.Sockets;
using Windows.Storage.Streams;
using Windows.UI.Core;

namespace PayPalRetailSDK.JsObjects
{
    class MiuraBluetoothDevice
    {
        DeviceInformation device;
        ObjectInstance jsValue;
        RfcommDeviceService connection;
        StreamSocket deviceSocket;
        DataWriter deviceWriter;
        CancellationTokenSource readTaskKiller;
        List<FunctionInstance> callbacks = new List<FunctionInstance>();

        public MiuraBluetoothDevice(DeviceInformation device)
        {
            this.device = device;

            ObjectInstance callbacks = RetailSDK.Engine.CreateJsObject();

            DelegateWrapper isConnected = RetailSDK.Engine.Wrap(new Func<bool>(() =>
            {
                return connection != null;
            }));
            DelegateWrapper connect = RetailSDK.Engine.Wrap(new Func<JsValue, bool>((jsCallback) =>
            {
                var task = CoreApplication.MainView.CoreWindow.Dispatcher.RunAsync(CoreDispatcherPriority.Normal, () =>
                {
                    this.Connect(jsCallback);
                });
                return true;
            }));
            DelegateWrapper disconnect = RetailSDK.Engine.Wrap(new Action(() =>
            {
                if (connection != null)
                {
                    this.Disconnect();    
                }
            }));
            DelegateWrapper send = RetailSDK.Engine.Wrap(new Func<JsValue, JsValue, bool>((data, callback) =>
            {
                if (deviceWriter != null)
                {
                    byte[] rawData;
                    if (data.IsObject())
                    {
                        var args = data.AsObject();
                        var fullData = args.Get("data").AsString();
                        var offset = (long)args.Get("offset").AsNumber();
                        var len = (long)args.Get("len").AsNumber();
                        // TODO could be cute about taking a substring of the base64 without converting it all.
                        rawData = new byte[len];
                        Array.Copy(Convert.FromBase64String(fullData), (int) offset, rawData, 0, (int) len);
                    }
                    else
                    {
                        rawData = Convert.FromBase64String(data.AsString());
                    }

                    this.WriteBytes(rawData);
                    if (!callback.IsNull() && !callback.IsUndefined())
                    {
                        callback.As<FunctionInstance>().Call(JsValue.Null, new JsValue[] { });
                    }
                    return true;
                }
                else
                {
                    if (!callback.IsNull() && !callback.IsUndefined())
                    {
                        // TODO don't throw string
                        callback.As<FunctionInstance>().Call(JsValue.Null, new JsValue[] { new JsValue("Device was not connected.") });
                    }
                    return false;
                }
            }));
            callbacks.FastAddProperty("isConnected", isConnected, false, true, true);
            callbacks.FastAddProperty("connect", connect, false, true, true);
            callbacks.FastAddProperty("disconnect", disconnect, false, true, true);
            callbacks.FastAddProperty("send", send, false, true, true);

            jsValue = PayPalRetailObject.CreateJSObject("MiuraDevice", new JsValue[] {
    	        new JsValue(device.Name),
		        callbacks,
		        new JsValue(false)
    		});
            RetailSDK.Engine.Js(() =>
            {
                jsValue.Put("manufacturer", "Miura", true);
                // Tell the SDK this device is ready to go.
                RetailSDK.jsSdk.Get("newDevice").As<FunctionInstance>().Call(RetailSDK.jsSdk, new JsValue[] { jsValue });
            });
        }

        public async void WriteBytes(byte[] bytes)
        {
            deviceWriter.WriteBytes(bytes);
            await deviceWriter.StoreAsync();
        }

        public async void Connect(JsValue callback)
        {
            var shouldConnect = true;
            lock (callbacks)
            {
                callbacks.Add(callback.As<FunctionInstance>());
                if (callbacks.Count > 1)
                {
                    shouldConnect = false;
                }
            }
            if (shouldConnect)
            {
                await ConnectWithRetry(2);
            }
        }

        private async Task ConnectWithRetry(int retryCount) {
            bool shouldRetry = false;
            try
            {
                connection = await RfcommDeviceService.FromIdAsync(device.Id);
                if (connection == null)
                {
                    NotifyCallbacks(RetailSDK.Engine.jsEngine.Error.Construct(new JsValue[] {
                        new JsValue("DEVICE_UNAVAILABLE")
                    }));
                    return;
                }

                deviceSocket = new StreamSocket();
                await deviceSocket.ConnectAsync(connection.ConnectionHostName, connection.ConnectionServiceName);

                deviceWriter = new DataWriter(deviceSocket.OutputStream);
                DataReader deviceReader = new DataReader(deviceSocket.InputStream);
                deviceReader.InputStreamOptions = InputStreamOptions.Partial;
                readTaskKiller = new CancellationTokenSource();
                ReceiveLoop(deviceReader, readTaskKiller.Token);
                NotifyCallbacks(JsValue.Undefined);
            }
            catch (Exception x)
            {
                if (retryCount > 0)
                {
                    shouldRetry = true;
                }
                else
                {
                    try
                    {
                        Disconnect();
                    }
                    catch (Exception)
                    {

                    }
                    NotifyCallbacks(RetailSDK.Engine.jsEngine.Error.Construct(new JsValue[] {
                        new JsValue(x.Message)
                    }));
                }
            }
            if (shouldRetry)
            {
                await ConnectWithRetry(--retryCount);
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
                        RetailSDK.Engine.Js(() =>
                        {
                            fi.Call(JsValue.Null, new JsValue[] { error });
                        });
                    }
                    catch (Exception) { }
                }
            }
        }

        public void Disconnect()
        {
            if (readTaskKiller != null)
            {
                readTaskKiller.Cancel();
            }
            if (deviceWriter != null)
            {
                deviceWriter.DetachStream();
                deviceWriter = null;
            }
            deviceSocket = null;
            connection = null;
        }

        private async void ReceiveLoop(DataReader deviceReader, CancellationToken token)
        {
            try
            {
                while (true)
                {
                    var count = await deviceReader.LoadAsync(16384);
                    if (count > 0)
                    {
                        byte[] data = new byte[count];
                        deviceReader.ReadBytes(data);
                        var base64 = Convert.ToBase64String(data);
                        try
                        {
                            RetailSDK.Engine.Js(() =>
                            {
                                jsValue.Get("received").As<FunctionInstance>().Call(jsValue, new JsValue[] {
                                    new JsValue(base64)
                                });
                            });
                        }
                        catch (Exception receiveException)
                        {
                            RetailSDK.LogViaJs("error", "native.device.miura.bluetooth", "Exception delivering data: " + receiveException.ToString());
                        }
                    }
                    else if (count == 0)
                    {
                        break;
                    }
                }
            }
            catch (OperationCanceledException)
            {
                deviceReader.DetachStream();
            }
        }
    }
}
