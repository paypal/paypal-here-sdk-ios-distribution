using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Windows.Foundation;

namespace PayPalRetailSDK.JsObjects
{
    class MiuraUsbDevice
    {
        public static uint VendorId = 0x525;
        public static uint[] ProductIds = new uint[] { 0xa4a5, 0xa4a7 };

        //private Windows.Devices.Enumeration.DeviceInformation deviceInfo;

        public MiuraUsbDevice(Windows.Devices.Enumeration.DeviceInformation deviceInfo)
        {
            //TODO a lot. Like implement it.
        }
    }
}
