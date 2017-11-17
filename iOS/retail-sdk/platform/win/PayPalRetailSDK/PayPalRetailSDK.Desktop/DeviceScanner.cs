using HidLibrary;
using InTheHand.Net.Sockets;
using PayPalRetailSDK.JsObjects;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Management;
using System.Threading;

namespace PayPalRetailSDK
{
    class DeviceScanner
    {
        Timer scanTimer;
        public static Dictionary<String, Object> KnownDevices = new Dictionary<string, object>();
        private const string LogComponentName = "paymentDevice";

        // Because BT operations can take a while, we need a little hint to stop doing things
        // while we're shutting down.
        int runCounter = 0;
        bool bluetoothIsSupported = true;

        public void StartWatching()
        {
            if (scanTimer != null) {
                return;
            }
            scanTimer = new Timer(SequentialCallBack, runCounter, TimeSpan.Zero, TimeSpan.FromMilliseconds(Timeout.Infinite));
        }

        public void StopWatching()
        {
            runCounter++;
            if (scanTimer != null)
            {
                var handle = new ManualResetEvent(false);
                scanTimer.Dispose(handle);
                scanTimer = null;
                handle.WaitOne();
            }
        }

        private void SequentialCallBack(object state)
        {
            var stopWatch = new Stopwatch();
            stopWatch.Start();
            try
            {
                Scan(state);
            }
            catch (Exception ex)
            {
                RetailSDK.LogViaJs("error", LogComponentName, string.Format("Timer callback logged an exception \n {0}", ex));
            }
            finally
            {
                ResetTimer();
            }
        }

        private void ResetTimer()
        {
            try
            {
                if (scanTimer != null)
                {
                    // TODO the decision of when and how often to scan probably belongs in JS
                    scanTimer.Change(TimeSpan.FromSeconds(10), TimeSpan.FromMilliseconds(Timeout.Infinite));
                }
            }
            catch (ObjectDisposedException ex)
            {
                //Until Microsoft provides a TryInvoke/TryChange method on timer, eat the ObjectDispose exception here
                //This exception is logged on accessing timer object after it was disposed
                RetailSDK.LogViaJs("warn", LogComponentName, string.Format("Tried resetting a disposed timer \n {0}", ex));
            }
        }

        void Scan(object state)
        {
            if (runCounter != (int)state)
            {
                // We were cancelled while the timer was firing.
                return;
            }

            // Do USB HID first since it's fast.
            foreach (var device in getUsbHidDevices())
            {
                if (!KnownDevices.ContainsKey(device.DevicePath) && device.Attributes.VendorId == 2049)
                {
                    bool addIt = false;
                    lock (KnownDevices)
                    {
                        if (!KnownDevices.ContainsKey(device.DevicePath))
                        {
                            // Pwn it
                            KnownDevices[device.DevicePath] = this;
                            addIt = true;
                        }
                    }
                    if (addIt)
                    {
                        MagtekUsbDevice newDevice = new MagtekUsbDevice(device);
                        KnownDevices[device.DevicePath] = newDevice;
                    }
                }
            }

            // And USB Miura...
            using (var searcher = new ManagementObjectSearcher("SELECT * FROM WIN32_SerialPort"))
            {
                var ports = searcher.Get().Cast<ManagementBaseObject>().ToList();
                foreach (var port in ports) {
                    var deviceId = port.Properties["DeviceID"];
                    if (deviceId == null || deviceId.Value == null || KnownDevices.ContainsKey(deviceId.Value.ToString()))
                    {
                        continue;
                    }
                    var deviceIdString = deviceId.Value.ToString();
                    var pnpId = port.Properties["PNPDeviceID"];
                    if (pnpId != null && pnpId.Value != null)
                    {
                        // TODO Temporarily disable USB as a device gets recognized both as USB and BT when connected over both means to the same PC. This is a big issue during firmware update reboots
                        //if (pnpId.Value.ToString().IndexOf("VID_0525&PID_A4A7") >= 0 ||
                        //    pnpId.Value.ToString().IndexOf("VID_0525&PID_A4A5") >= 0)
                        //{
                        //    // Miura USB device
                        //    var addIt = false;
                        //    lock (KnownDevices)
                        //    {
                        //        if (!KnownDevices.ContainsKey(deviceIdString))
                        //        {
                        //            // Pwn it
                        //            KnownDevices[deviceIdString] = this;
                        //            addIt = true;
                        //        }
                        //    }
                        //    if (addIt)
                        //    {
                        //        MiuraUsbDevice newDevice = new MiuraUsbDevice(deviceIdString);
                        //        KnownDevices[deviceIdString] = newDevice;
                        //    }
                        //}
                    }
                }
            } 

            var client = getClient();
            if (client != null)
            {
                client.InquiryLength = TimeSpan.FromSeconds(3);
                BluetoothDeviceInfo[] list = client.DiscoverDevices();
                if (runCounter != (int)state)
                {
                    // We were cancelled while waiting.
                    return;
                }
                foreach (var device in list)
                {
                    if (device.DeviceName.StartsWith("PayPal ") && !KnownDevices.ContainsKey(device.DeviceAddress.ToString()) && device.Authenticated)
                    {
                        RetailSDK.LogViaJs("debug", LogComponentName, string.Format("Bluetooth|Found device {0} will try initializing it.", device.DeviceName));
                        var addIt = false;
                        lock (KnownDevices)
                        {
                            if (!KnownDevices.ContainsKey(device.DeviceAddress.ToString()))
                            {
                                // Pwn it
                                KnownDevices.Add(device.DeviceAddress.ToString(), this);
                                addIt = true;
                            }
                        }
                        if (addIt)
                        {
                            MiuraBluetoothDevice newDevice = new MiuraBluetoothDevice(device);
                            KnownDevices[device.DeviceAddress.ToString()] = newDevice;
                        }
                    }
                }
            }
        }

        /**
         * For testing with mocks
         **/
        BluetoothClient getClient() {
            if (!bluetoothIsSupported)
            {
                return null;
            }
            try
            {
                return new BluetoothClient();
            }
            catch (PlatformNotSupportedException)
            {
                bluetoothIsSupported = false;
                return null;
            }
        }

        IEnumerable<HidDevice> getUsbHidDevices()
        {
            return HidLibrary.HidDevices.Enumerate();
        }
    }
}
