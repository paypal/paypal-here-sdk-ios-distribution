using PayPalRetailSDK.JsObjects;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using Windows.ApplicationModel.Core;
using Windows.Devices.Bluetooth.Rfcomm;
#if !WINDOWS_PHONE_APP
using Windows.Devices.PointOfService;
#endif
using Windows.Devices.Enumeration;
using Windows.Foundation;
using Windows.UI.Core;

namespace PayPalRetailSDK
{
    class DeviceManager
    {
        private List<DeviceWatcher> watchers = new List<DeviceWatcher>();
        private Dictionary<String, Object> knownDevices = new Dictionary<string, Object>();

        public DeviceManager()
        {
            CoreApplication.Exiting += CoreApplication_Exiting;
            CoreApplication.Suspending += CoreApplication_Suspending;
            var watcher = Windows.Devices.Enumeration.DeviceInformation.CreateWatcher(RfcommDeviceService.GetDeviceSelector(RfcommServiceId.SerialPort));
            watcher.Added += BluetoothDeviceAdded;
            watchers.Add(watcher);

#if !WINDOWS_PHONE_APP
            watcher = Windows.Devices.Enumeration.DeviceInformation.CreateWatcher(MagneticStripeReader.GetDeviceSelector());
            watcher.Added += MagReaderDeviceAdded;
            watchers.Add(watcher);

            foreach (var pid in MiuraUsbDevice.ProductIds)
            {
                var miura = Windows.Devices.Usb.UsbDevice.GetDeviceSelector(MiuraUsbDevice.VendorId, pid);
                watcher = Windows.Devices.Enumeration.DeviceInformation.CreateWatcher(miura);
                watcher.Added += MiuraDeviceAdded;
                watchers.Add(watcher);
            }
#endif
        }

        void AnyDeviceAdded(DeviceWatcher sender, DeviceInformation args)
        {
            if (args.Name.StartsWith("ELMO") && args.IsEnabled)
            {
                var device = new MiuraUsbDevice(args);
            }
        }

        void CoreApplication_Suspending(object sender, Windows.ApplicationModel.SuspendingEventArgs e)
        {
        }

        void CoreApplication_Exiting(object sender, object e)
        {
        }

        public void StartWatching()
        {
            foreach (DeviceWatcher watcher in watchers)
            {
                watcher.Start();
            }
        }

        public void StopWatching()
        {
            foreach (DeviceWatcher watcher in watchers)
            {
                if (watcher.Status == DeviceWatcherStatus.Started)
                {
                    watcher.Stop();
                }
            }
            foreach (var device in knownDevices)
            {
                var miura = device.Value as MiuraBluetoothDevice;
                if (miura != null)
                {
                    miura.Disconnect();
                }
#if !WINDOWS_PHONE_APP
                var mag = device.Value as WindowsMagneticCardReader;
                if (mag != null)
                {
                    mag.Disconnect();
                }
#endif
                var inprocess = device.Value as IAsyncAction;
                if (inprocess != null)
                {
                    inprocess.Cancel();
                }
            }
        }

#if !WINDOWS_PHONE_APP
        void MagReaderDeviceAdded(Windows.Devices.Enumeration.DeviceWatcher sender, Windows.Devices.Enumeration.DeviceInformation args)
        {
            // The dance here is complicated. We're on some OS thread, but we need to make sure
            // there isn't some other scan active (since devie startup could take a while).
            // So we first store the TASK that is in charge of making the reader, then we'll
            // swap it out with the actual reader.
            lock (knownDevices)
            {
                if (knownDevices.ContainsKey(args.Id))
                {
                    return;
                }
                IAsyncAction task = null;
                task = RetailSDK.RunAsync(() =>
                {
                    try
                    {
                        if (knownDevices[args.Id] == task)
                        {
                            RetailSDK.Engine.Js(() =>
                            {
                                WindowsMagneticCardReader newDevice = new WindowsMagneticCardReader(args);
                                knownDevices[args.Id] = newDevice;
                            });
                        }
                    }
                    catch (Exception x)
                    {
                        Debug.WriteLine(x);
                    }
                });
                if (task != null)
                {
                    knownDevices.Add(args.Id, task);
                }
            }
        }

        void MiuraDeviceAdded(Windows.Devices.Enumeration.DeviceWatcher sender, Windows.Devices.Enumeration.DeviceInformation args)
        {

        }

#endif

        void BluetoothDeviceAdded(Windows.Devices.Enumeration.DeviceWatcher sender, Windows.Devices.Enumeration.DeviceInformation args)
        {
            if (args.Name.StartsWith("PayPal "))
            {
                lock (knownDevices)
                {
                    if (knownDevices.ContainsKey(args.Id))
                    {
                        return;
                    }
                    IAsyncAction task = null;
                    task = RetailSDK.RunAsync(() =>
                    {
                        try
                        {
                            if (knownDevices[args.Id] == task)
                            {
                                RetailSDK.Engine.Js(() =>
                                {
                                    MiuraBluetoothDevice newDevice = new MiuraBluetoothDevice(args);
                                    knownDevices[args.Id] = newDevice;
                                });
                            }
                        }
                        catch (Exception x)
                        {
                            Debug.WriteLine(x);
                        }
                    });
                    if (task != null)
                    {
                        knownDevices.Add(args.Id, task);
                    }
                }
            }
        }
    }
}
