using InTheHand.Net;
using InTheHand.Net.Bluetooth;
using InTheHand.Net.Sockets;
using Jint.Native;
using Jint.Native.Function;
using System;
using System.Linq;
using System.Net.Sockets;
using Manticore;

namespace PayPalRetailSDK.JsObjects
{
    // TODO probably some locking.
    class MiuraBluetoothDevice : PayPalRetailObject
    {
        private readonly BluetoothDeviceInfo _device;
        BluetoothClient _deviceClient;
        NetworkStream _deviceStream;
        private readonly SynchronizedCallbackStore<FunctionInstance> _jsCallbacks = new SynchronizedCallbackStore<FunctionInstance>();
        private const string LogComponentName = "native.MiuraBluetoothDevice";

        public MiuraBluetoothDevice(BluetoothDeviceInfo deviceInfo)
        {
            _device = deviceInfo;
            _deviceClient = new BluetoothClient();
            Hookup();
        }

        void Hookup()
        {
            var callbacks = Engine.CreateJsObject();
            var isConnected = Engine.Wrap(new Func<bool>(() => _deviceClient.Connected));
            var setTimeout = Engine.ManticoreJsObject.Get("setTimeout").As<FunctionInstance>();
            var asyncInvokeCallback = new Action<JsValue, JsValue[]> ((cb, args) =>
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
            var connect = Engine.Wrap(new Action<JsValue>(jsCallback =>
            {
                if (!_deviceClient.Connected)
                {
                    var callback = jsCallback.As<FunctionInstance>();
                    if (_jsCallbacks.Add(callback) > 1)
                    {
                        return;
                    }

                    try
                    {
                        var endpoint = new BluetoothEndPoint(_device.DeviceAddress, BluetoothService.SerialPort);
                        _deviceClient.BeginConnect(endpoint, OnConnected, null);
                        RetailSDK.LogViaJs("debug", LogComponentName,
                            $"Initializing bluetooth  connect sequence with {_device.DeviceName}...");
                    }
                    catch (Exception ex)
                    {
                        RetailSDK.LogViaJs("error", LogComponentName,
                            $"Begin bluetooth connect with {_device.DeviceName} failed. Connect Status: {_deviceClient.Connected}, Callback count: {_jsCallbacks.Count}");
                        if (_deviceClient.Connected || _jsCallbacks.Count <= 0)
                        {
                            return;
                        }
                        _jsCallbacks.Remove(callback);

                        var error = new JsErrorBuilder(Engine, ex).Build();
                        asyncInvokeCallback(jsCallback, new JsValue[] { error });
                    }
                }
                else
                {
                    RetailSDK.LogViaJs("debug", LogComponentName, $"Ignore device connection sequence as {_device.DeviceName} was already connected");
                    asyncInvokeCallback(jsCallback, ManticoreEngine.EmptyArgs);
                }
            }));
            var disconnect = Engine.Wrap(new Action<JsValue>(callback =>
            {
                if (_deviceClient.Connected)
                {
                    try
                    {
                        _deviceClient.Close();
                        _jsCallbacks.Clear();
                        _deviceStream = null;
                        _deviceClient = new BluetoothClient();
                        asyncInvokeCallback(callback, ManticoreEngine.EmptyArgs);
                        RetailSDK.LogViaJs("debug", LogComponentName, $"Successfully disconnected with {_device.DeviceName}");
                    }
                    catch (Exception ex)
                    {
                        RetailSDK.LogViaJs("debug", LogComponentName, $"Error on disconnecting with {_device.DeviceName}: {ex} ");
                        var error = new JsErrorBuilder(Engine, ex).Build();
                        asyncInvokeCallback(callback, new JsValue[] { error });
                    }
                }
                else
                {
                    RetailSDK.LogViaJs("debug", LogComponentName, $"Ignore disconnect request as {_device.DeviceName} was already disconnected");
                    asyncInvokeCallback(callback, ManticoreEngine.EmptyArgs);
                }
            }));
            var send = Engine.Wrap(new Action<JsValue, JsValue>((data, callback) =>
            {
                var error = JsValue.Null;
                try
                {
                    if (_deviceStream == null || !_deviceStream.CanWrite)
                    {
                        error = new JsErrorBuilder(Engine, new Exception("Device not connected")).Build();
                        return;
                    }
                    byte[] rawData;
                    if (data.IsObject())
                    {
                        var args = data.AsObject();
                        var fullData = args.Get("data").AsString();
                        var offset = (long) args.Get("offset").AsNumber();
                        var len = (long) args.Get("len").AsNumber();
                        // TODO could be cute about taking a substring of the base64 without converting it all.
                        rawData = new byte[len];
                        Array.Copy(Convert.FromBase64String(fullData), offset, rawData, 0, len);
                    }
                    else
                    {
                        rawData = Convert.FromBase64String(data.AsString());
                    }
                    _deviceStream.Write(rawData, 0, rawData.Length);
                }
                catch (Exception ex)
                {
                    RetailSDK.LogViaJs("error", LogComponentName, $"Failed to send command to {_device.DeviceName} : {ex}");
                    error = new JsErrorBuilder(Engine, ex).Build();
                }
                finally
                {
                    asyncInvokeCallback(callback, error == JsValue.Null ? ManticoreEngine.EmptyArgs : new [] { error });
                }
            }));
            callbacks.FastAddProperty("isConnected", isConnected, false, true, true);
            callbacks.FastAddProperty("connect", connect, false, true, true);
            callbacks.FastAddProperty("disconnect", disconnect, false, true, true);
            callbacks.FastAddProperty("send", send, false, true, true);

            Engine.Js(() =>
            {
                impl = CreateJSObject("MiuraDevice", new [] {
    	            new JsValue(_device.DeviceName),
		            callbacks,
		            new JsValue(false)
    		    });
                impl.Put("manufacturer", "Miura", true);
                RetailSDK.jsSdk.DiscoveredPaymentDevice(new PaymentDevice(impl));
                impl.Get("connect").As<FunctionInstance>().Call(impl, ManticoreEngine.EmptyArgs);
            });
        }

        private void OnConnected(IAsyncResult ar)
        {
            if (ar.IsCompleted && _deviceClient.Connected)
            {
                _deviceStream = _deviceClient.GetStream();
                NotifyConnectionAttempt(JsValue.Null);
                ReceiveLoop();
                RetailSDK.LogViaJs("debug", LogComponentName, $"Successfully opened connection stream with {_device.DeviceName}");
            }
            else
            {
                _deviceClient.Close();
                _deviceClient = new BluetoothClient();
                RetailSDK.LogViaJs("debug", LogComponentName, $"Could not connect to {_device.DeviceName}");
                NotifyConnectionAttempt(new JsErrorBuilder(Engine, new Exception("Connection failed")).Build());
            }
        }

        private void NotifyConnectionAttempt(JsValue error)
        {
            var snapshot = _jsCallbacks.Callbacks.ToList();
            _jsCallbacks.Clear();
            foreach (var fi in snapshot.Where(x => x != null).ToList())
            {
                try
                {
                    Engine.Js(() => { fi.Call(JsValue.Null, new[] { error }); });
                    _jsCallbacks.Remove(fi);
                }
                catch (Exception ex)
                {
                    RetailSDK.LogViaJs("error", LogComponentName, "Exception invoking callback from notifyConnectionAttempt: " + ex);
                }
            }
        }

        private async void ReceiveLoop()
        {
            var readBuffer = new byte[4096];
            while (true)
            {
                if (!_deviceClient.Connected || _deviceStream == null)
                {
                    var error = new JsErrorBuilder(Engine, new Exception("Device was disconnected")).Build();
                    Engine.Js(() => impl.Get("onDisconnected").As<FunctionInstance>().Call(impl, new JsValue[] { error }));
                    RetailSDK.LogViaJs("info", LogComponentName, $"{_device.DeviceName} Exiting receive loop as stream was null. Perhaps the device was disconnected?");
                    break;
                }

                try
                {
                    var count = await _deviceStream.ReadAsync(readBuffer, 0, readBuffer.Length);
                    if (count <= 0)
                    {
                        continue;
                    }
                    var bytesIn = Convert.ToBase64String(readBuffer, 0, count);
                    Engine.Js(() => impl.Get("received").As<FunctionInstance>().Call(impl, new[] { new JsValue(bytesIn) }));
                }
                catch (Exception ex)
                {
                    //We encountered an error probably because of a disconnect request
                    //ignore the error and then exit the ReceiveLoop if deviceStream is null
                    RetailSDK.LogViaJs("error", LogComponentName, $"Received error while handling data stream from {_device.DeviceName}\n{ex}");
                }
            }
        }
    }
}
