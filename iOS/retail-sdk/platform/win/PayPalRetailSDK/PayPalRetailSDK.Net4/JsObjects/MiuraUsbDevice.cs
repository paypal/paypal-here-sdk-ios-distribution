using System;
using System.IO.Ports;
using System.Linq;
using System.Threading;
using Jint.Native;
using Jint.Native.Function;
using Manticore;

namespace PayPalRetailSDK.JsObjects
{
    class MiuraUsbDevice : PayPalRetailObject
    {
        private readonly SerialPort _device;
        private const string LogComponentName = "native.MiuraUsbDevice";
        private readonly object _lockObj = new object();
        private bool _isOpen;

        public MiuraUsbDevice(string portName)
        {
            _device = new SerialPort(portName);
            _device.DataReceived += device_DataReceived;
            _device.PinChanged += device_PinChanged;
            var callbacks = Engine.CreateJsObject();
            var isConnected = Engine.Wrap(new Func<bool>(() => IsDeviceConnected(portName)));
            var setTimeout = Engine.ManticoreJsObject.Get("setTimeout").As<FunctionInstance>();
            var asyncInvokeCallback = new Action<JsValue, JsValue[]>((cb, args) =>
            {
                if (Engine.IsNullOrUndefined(cb))
                {
                    return;
                }

                setTimeout.Call(Engine.ManticoreJsObject, new[]
                {
                    new JsValue(Engine.AsJsFunction((thisObject, arg) =>
                    {
                        cb.As<FunctionInstance>().Call(impl, args);
                        return JsValue.Undefined;
                    })), 0 
                });
            });
            var connect = Engine.Wrap(new Action<JsValue>(callback =>
            {
                lock (_lockObj)
                {
                    if (!_device.IsOpen)
                    {
                        var error = JsValue.Null;
                        try
                        {
                            _device.Open();
                            _isOpen = true;
                        }
                        catch (Exception ex)
                        {
                            //We could get COM PORT does not exist error while attempting a connect after restart
                            error = new JsErrorBuilder(Engine, ex).Build();
                        }

                        asyncInvokeCallback(callback, error == JsValue.Null ? ManticoreEngine.EmptyArgs : new[] { error });
                    }
                    else
                    {
                        asyncInvokeCallback(callback, ManticoreEngine.EmptyArgs);
                    }
                }
            }));
            var send = Engine.Wrap(new Action<JsValue, JsValue>((data, callback) =>
            {
                byte[] rawData;
                var error = JsValue.Null;

                if (NotifyOnDeviceDisconnect())
                {
                    error = new JsErrorBuilder(Engine, new Exception("Device not connected")).Build();
                    asyncInvokeCallback(callback, new[] {error});
                    return;
                }

                if (data.IsObject())
                {
                    var args = data.AsObject();
                    var fullData = args.Get("data").AsString();
                    var offset = (long)args.Get("offset").AsNumber();
                    var len = (long)args.Get("len").AsNumber();
                    // TODO could be cute about taking a substring of the base64 without converting it all.
                    rawData = new byte[len];
                    Array.Copy(Convert.FromBase64String(fullData), offset, rawData, 0, len);
                }
                else
                {
                    rawData = Convert.FromBase64String(data.AsString());
                }

                try
                {
                    _device.Write(rawData, 0, rawData.Length);
                }
                catch (Exception ex)
                {
                    RetailSDK.LogViaJs("error", LogComponentName, $"Failed to send command to {_device.PortName} : {ex}");
                    error = new JsErrorBuilder(Engine, ex).Build();
                }

                asyncInvokeCallback(callback, error == JsValue.Null ? ManticoreEngine.EmptyArgs : new[] { error });
            }));
            var disconnect = Engine.Wrap(new Action<JsValue>(callback =>
            {
                var error = JsValue.Null;
                if (!_device.IsOpen)
                {
                    error = new JsErrorBuilder(Engine, new Exception("Device is not currently connected")).Build();
                    asyncInvokeCallback(callback, new[] {error});
                    return;
                }

                _isOpen = false;
                var closeSerialPort = new Thread(() =>
                {
                    try
                    {
                        _device.Close();
                    }
                    catch (Exception ex)
                    {
                        RetailSDK.LogViaJs("debug", LogComponentName, $"Error on disconnecting with {_device.PortName}: {ex} ");
                        error = new JsErrorBuilder(Engine, ex).Build();
                    }

                    asyncInvokeCallback(callback, error == JsValue.Null ? ManticoreEngine.EmptyArgs : new [] {error});
                });
                closeSerialPort.Start();
            }));

            callbacks.FastAddProperty("isConnected", isConnected, false, true, true);
            callbacks.FastAddProperty("connect", connect, false, true, true);
            callbacks.FastAddProperty("disconnect", disconnect, false, true, true);
            callbacks.FastAddProperty("send", send, false, true, true);

            Engine.Js(() =>
            {
                impl = CreateJSObject("MiuraDevice", new[] {
    	            new JsValue(_device.PortName),
		            callbacks,
		            new JsValue(true)
    		    });
                impl.Put("manufacturer", "Miura", true);
                RetailSDK.jsSdk.DiscoveredPaymentDevice(new PaymentDevice(impl));
                impl.Get("connect").As<FunctionInstance>().Call(impl, ManticoreEngine.EmptyArgs);
            });
        }

        private void device_PinChanged(object sender, SerialPinChangedEventArgs e)
        {
            RetailSDK.LogViaJs("debug", LogComponentName, $"SerialPort changed event type {e.EventType} for {_device.PortName}");
            NotifyOnDeviceDisconnect();
        }

        private bool NotifyOnDeviceDisconnect()
        {
            try
            {
                if (!IsDeviceConnected(_device.PortName))
                {
                    RetailSDK.LogViaJs("warn", LogComponentName, $"{_device.PortName} was disconnected");
                    var error = new JsErrorBuilder(Engine, new Exception("Device was disconnected")).Build();
                    Engine.Js(() => impl.Get("onDisconnected").As<FunctionInstance>().Call(impl, new JsValue[] { error }));
                    return true;
                }
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, $"Received error while emitting disconnected event {_device.PortName}\n{ex}");
            }

            return false;
        }

        private bool IsDeviceConnected(string portName)
        {
            return SerialPort.GetPortNames().Contains(portName) && _device.IsOpen;
        }

        private void device_DataReceived(object sender, SerialDataReceivedEventArgs e)
        {
            RetailSDK.LogViaJs("debug", LogComponentName, $"Received data from reader. EventType: {e.EventType} BytesToRead: {_device.BytesToRead}");
            if (e.EventType == SerialData.Chars)
            {
                while (_isOpen && _device.BytesToRead > 0)
                {
                    var bytes = new byte[_device.BytesToRead];
                    _device.Read(bytes, 0, bytes.Length);
                    try
                    {
                        RetailSDK.Engine.Js(() =>
                        {
                            impl.Get("received").As<FunctionInstance>().Call(impl, new[] { new JsValue(Convert.ToBase64String(bytes)) });
                        });
                    }
                    catch (Exception ex)
                    {
                        RetailSDK.LogViaJs("error", LogComponentName, $"Received error while handling data stream from {_device.PortName}\n{ex}");
                    }
                }
            }
            else
            {
                if (_isOpen)
                {
                    // TODO Not yet handled - I'm not sure what EOF from the terminal really means...
                }
            }
        }
    }
}
