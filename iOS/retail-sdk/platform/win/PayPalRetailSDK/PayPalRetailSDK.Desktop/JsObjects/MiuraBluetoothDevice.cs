using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Linq;
using System.Net.Sockets;
using InTheHand.Net;
using InTheHand.Net.Bluetooth;
using InTheHand.Net.Sockets;
using Manticore;
using Microsoft.CSharp.RuntimeBinder;

namespace PayPalRetailSDK.JsObjects
{
    class MiuraBluetoothDevice : PayPalRetailObject
    {
        private readonly BluetoothDeviceInfo _device;
        private BluetoothClient _deviceClient;
        private NetworkStream _deviceStream;
        private readonly SynchronizedCallbackStore<object> _jsCallbacks = new SynchronizedCallbackStore<object>();
        private const string LogComponentName = "native.MiuraBluetoothDevice";
        internal const string ManufacturerName = "MIURA";
        internal const string M010ModelName = "M010";
        internal const string JsDeviceBuilder = "DeviceBuilder";

        public MiuraBluetoothDevice(BluetoothDeviceInfo device)
        {
            _device = device;
            _deviceClient = new BluetoothClient();
            Hookup();
        }

        private void Hookup()
        {
            dynamic callbacks = Engine.CreateJsObject();
            callbacks.isConnected = new Func<bool>(() => _deviceClient.Connected);
            callbacks.removed = new Action<dynamic>(callback =>
            {
                if (DeviceScanner.KnownDevices.ContainsKey(_device.DeviceAddress.ToString()))
                {
                    DeviceScanner.KnownDevices.Remove(_device.DeviceAddress.ToString());
                }
                callback(null);
            });
            callbacks.connect = new Action<dynamic>(callback =>
            {
                if (!_deviceClient.Connected)
                {
                    var endpoint = new BluetoothEndPoint(_device.DeviceAddress, BluetoothService.SerialPort);
                    if (_jsCallbacks.Add(callback) > 1)
                    {
                        return;
                    }

                    try
                    {
                        _deviceClient.BeginConnect(endpoint, OnConnected, null);
                        RetailSDK.LogViaJs("debug", LogComponentName, "BeginConnect...");
                    }
                    catch(Exception ex)
                    {
                        //Looks like we connected between the previous attempt and this one
                        //Callback with error if we are not connected
                        var isConnected = _deviceClient.Connected;
                        RetailSDK.LogViaJs("error", LogComponentName, $"BeginConnect callback. Connected: {isConnected}, Callback count: {_jsCallbacks.Count}");
                        if (_deviceClient.Connected || _jsCallbacks.Count <= 0)
                        {
                            return;
                        }

                        _jsCallbacks.Remove(callback);
                        Engine.ManticoreJsObject.setTimeout(new Action(() => { callback(new JsErrorBuilder(ex).Build()); }), 0);
                    }
                }
                else
                {
                    RetailSDK.LogViaJs("debug", LogComponentName, "Already connected.");
                    Engine.ManticoreJsObject.setTimeout(new Action(() => { callback(null); }), 0);
                }
            });
            callbacks.disconnect = new Func<dynamic, bool>(callback =>
            {
                var disconnectResult = true;
                if (_deviceClient.Connected)
                {
                    dynamic callbackVal = null;                    
                    try
                    {                        
                        _deviceClient.Close();
                        _jsCallbacks.Clear();
                        RetailSDK.LogViaJs("debug", LogComponentName, "Begin Disconnect...");
                        _deviceStream = null;
                        _deviceClient = new BluetoothClient();
                    }
                    catch(Exception ex)
                    {
                        RetailSDK.LogViaJs("error", LogComponentName, "Disconnect error: " + ex);
                        disconnectResult = false;
                        callbackVal = new JsErrorBuilder(ex).Build();;
                    }
                    finally
                    {
                        RetailSDK.LogViaJs("debug", LogComponentName, "End Disconnect");
                    }

                    if (!Engine.IsNullOrUndefined(callback))
                    {
                        callback(callbackVal);
                    }
                }
                else
                {
                    RetailSDK.LogViaJs("debug", LogComponentName, "Already disconnected.");
                    if (!Engine.IsNullOrUndefined(callback))
                    {
                        Engine.ManticoreJsObject.setTimeout(new Action(() => { callback(null); }), 0);
                    }
                }

                return disconnectResult;
            });
            callbacks.send = new Action<dynamic, dynamic>((data, callback) =>
            {
                try
                {
                    if (!_deviceClient.Connected || _deviceStream == null || !_deviceStream.CanWrite)
                    {
                        return;
                    }

                    byte[] rawData;
                    if (data is string)
                    {
                        rawData = Convert.FromBase64String(data);
                    }
                    else 
                    {
                        // I still don't trust Clearscript that it isn't a string...
                        try
                        {
                            var fullData = Convert.FromBase64String(data.data);
                            var offset = (int)data.offset;
                            var length = (int)data.len;
                            // TODO could be cute about taking a substring of the base64 without converting it all.
                            rawData = new byte[length];
                            Array.Copy(fullData, offset, rawData, 0, length);
                        }
                        catch (RuntimeBinderException)
                        {
                            rawData = Convert.FromBase64String(data);
                        }
                    }
                    _deviceStream.Write(rawData, 0, rawData.Length);
                    if (!Engine.IsNullOrUndefined(callback))
                    {
                        callback(null);
                    }
                }
                catch (Exception ex)
                {
                    RetailSDK.LogViaJs("error", LogComponentName, $"Failed to send command to {_device.DeviceName} : {ex}");
                    if (!Engine.IsNullOrUndefined(callback))
                    {
                        callback(new JsErrorBuilder(ex).Build());
                    }
                }
            });

            Engine.Js(() =>
            {
                var deviceBuilder = Engine.CreateJsObject(JsDeviceBuilder, new ExpandoObject());
                impl = deviceBuilder.build(ManufacturerName, _device.DeviceName, false, callbacks);
                impl.manufacturer = ManufacturerName;
                RetailSDK.jsSdk.DiscoveredPaymentDevice(new PaymentDevice(impl));
                impl.connect();
            });
        }

        private void OnConnected(IAsyncResult ar)
        {
            if (_deviceClient.Connected)
            {
                RetailSDK.LogViaJs("debug", LogComponentName, "OnConnected wait for deviceClient.Connected.");
                _deviceStream = _deviceClient.GetStream();
                ReceiveLoop();
                NotifyConnectionAttempt(null);
            }
            else
            {
                RetailSDK.LogViaJs("debug", LogComponentName, "OnConnected wait for deviceClient NOT Connected.");
                _deviceClient.Close();
                _deviceClient = new BluetoothClient();
                NotifyConnectionAttempt("Not connected");
            }
        }

        private void NotifyConnectionAttempt(object error)
        {
            var snapshot = _jsCallbacks.Callbacks.ToList();
            _jsCallbacks.Clear();
            foreach (dynamic cb in snapshot.ToList())
            {
                try
                {
                    cb(error);
                    _jsCallbacks.Remove(cb);
                }
                catch (Exception ex)
                {
                    RetailSDK.LogViaJs("error", LogComponentName, "Exception invoking callback from notifyConnectionAttempt: " + ex);
                }
            }
            _jsCallbacks.Clear();
        }

        private async void ReceiveLoop()
        {
            var readBuffer = new byte[4096];
            while (true)
            {
                if (!_deviceClient.Connected || _deviceStream == null)
                {
                    impl.onDisconnected(new JsErrorBuilder(new Exception("Device was disconnected")).Build());
                    RetailSDK.LogViaJs("info", LogComponentName, string.Format("{0} Exiting receive loop as stream was null. Perhaps the device was disconnected?", _device.DeviceName));
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
                    Engine.Js(() => { impl.received(bytesIn); });
                }
                catch (Exception ex)
                {
                    //We encountered an error probably because of a disconnect request
                    //ignore the error and then exit the ReceiveLoop if deviceStream is null
                    RetailSDK.LogViaJs("error", LogComponentName, string.Format("Received error while handling data stream from {0}\n{1}", _device.DeviceName, ex));
                }
            }

            RetailSDK.LogViaJs("debug", LogComponentName, "ReceiveLoop end.");
        }
    }
}
