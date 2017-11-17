using System;
using System.Dynamic;
using System.IO.Ports;
using System.Linq;
using System.Threading;
using Manticore;

namespace PayPalRetailSDK.JsObjects
{
    class MiuraUsbDevice : PayPalRetailObject
    {
        private readonly string _portName;
        private readonly SerialPort _device;
        private const string LogComponentName = "native.MiuraUsbDevice";
        private bool _isOpen;
        private readonly object _lockObj = new object();

        public MiuraUsbDevice(string port)
        {
            _portName = port;
            _device = new SerialPort(port);
            _device.DataReceived += device_DataReceived;
            _device.PinChanged += device_PinChanged;
            dynamic callbacks = Engine.CreateJsObject();
            callbacks.isConnected = new Func<bool>(IsDeviceConnected);
            callbacks.connect = new Action<dynamic>(callback =>
            {
                lock (_lockObj)
                {
                    if (!_device.IsOpen)
                    {
                        try
                        {
                            _device.Open();
                            _isOpen = true;
                            callback(null);
                        }
                        catch (Exception ex)
                        {
                            //We could get COM PORT does not exist error while attempting a connect after restart
                            RetailSDK.LogViaJs("error", LogComponentName, $"Could not open connection to {_portName}, Error: {ex.Message}");
                            callback(new JsErrorBuilder(ex).Build());
                        }
                    }
                    else
                    {
                        RetailSDK.LogViaJs("debug", LogComponentName, "Already connected.");
                        callback(null);
                    }
                }
            });
            callbacks.send = new Action<dynamic, dynamic>((data, callback) =>
            {
                dynamic err = null;
                if (NotifyOnDeviceDisconnect())
                {
                    err = new JsErrorBuilder(new Exception("Device not connected")).Build();
                    if (!Engine.IsNullOrUndefined(callback))
                    {
                        callback(err);
                    }
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
                        var fullData = Convert.FromBase64String((string)data.data);
                        var offset = (int)data.offset;
                        var length = (int)data.len;
                        // TODO could be cute about taking a substring of the base64 without converting it all.
                        rawData = new byte[length];
                        Array.Copy(fullData, offset, rawData, 0, length);
                    }
                    catch (Microsoft.CSharp.RuntimeBinder.RuntimeBinderException)
                    {
                        rawData = Convert.FromBase64String(data);
                    }
                }

                try
                {
                    _device.Write(rawData, 0, rawData.Length);
                }
                catch (Exception ex)
                {
                    RetailSDK.LogViaJs("error", LogComponentName, string.Format("Failed to send command to {0} : {1}", _device.PortName, ex));
                    err = new JsErrorBuilder(ex).Build();
                }

                if (!Engine.IsNullOrUndefined(callback))
                {
                    callback(err);
                }
            });
            callbacks.disconnect = new Action<dynamic>(callback =>
            {
                if (!_device.IsOpen)
                {
                    if (Engine.IsNullOrUndefined(callback))
                    {
                        return;
                    }
                    callback(new JsErrorBuilder(new Exception("Device is not currently connected.")).Build());
                    return;
                }

                _isOpen = false;
                var closeSerialPort = new Thread(() =>
                {
                    dynamic error = null;
                    try
                    {
                        _device.Close();
                    }
                    catch (Exception ex)
                    {
                        RetailSDK.LogViaJs("debug", LogComponentName, string.Format("Error on disconnecting with {0}: {1} ", _device.PortName, ex));
                        error = new JsErrorBuilder(ex).Build();
                    }

                    Engine.Js(() =>
                    {
                        if (Engine.IsNullOrUndefined(callback))
                        {
                            return;
                        }
                        callback(error);
                    });
                });
                closeSerialPort.Start();
            });
            Engine.Js(() =>
            {
                var deviceBuilder = Engine.CreateJsObject(MiuraBluetoothDevice.JsDeviceBuilder, new ExpandoObject());
                impl = deviceBuilder.build(MiuraBluetoothDevice.ManufacturerName, MiuraBluetoothDevice.M010ModelName, _portName, true, callbacks);
                impl.manufacturer = MiuraBluetoothDevice.ManufacturerName;
                RetailSDK.jsSdk.DiscoveredPaymentDevice(new PaymentDevice(impl));
                impl.connect();
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
                if (!IsDeviceConnected())
                {
                    impl.onDisconnected(new JsErrorBuilder(new Exception("Device was disconnected")).Build());
                    return true;
                }
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, $"Received error while emitting disconnected event {_device.PortName}\n{ex}");
            }

            return false;
        }

        private bool IsDeviceConnected()
        {
            var isConnected = SerialPort.GetPortNames().Contains(_portName) && _device.IsOpen;
            return isConnected;
        }

        void device_DataReceived(object sender, SerialDataReceivedEventArgs e)
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
                        Engine.Js(() =>
                        {
                            impl.received(Convert.ToBase64String(bytes));
                        });
                    }
                    catch (Exception ex)
                    {
                        RetailSDK.LogViaJs("error", LogComponentName, string.Format("Received error while handling data stream from {0}\n{1}", _device.PortName, ex));
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
