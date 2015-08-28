Required Frameworks
=====================
When building with the iOS PayPal Here SDK you'll need to add the following frameworks/libraries in your project's "Link Binary With Libraries" build phase:

AudioToolbox.framework
MobileCoreServices.framework
Security.framework
CFNetwork.framework
AVFoundation.framework
ExternalAccessory.framework
MediaPlayer.framework
CoreTelephony.framework
Foundation.framework 
CoreBluetooth.framework
SystemConfiguration.framework
libsqlite3.dylib
libz.dylib
libxml2.dylib


Linker Flags
=====================
Depending on your Xcode version and base SDK choice you may also need these flags in your project's 'Other Linker Flags' build setting:

-lstdc++
-stdlib=libstdc++
-ObjC


Reader Accessory Protocols
=====================
The following protocols must be added in your project's "Supported external accessory protocols" plist entry if you wish to connect to the associated reader.

M010 and M003 Bluetooth EMV Reader - com.paypal.here.reader
Magtek iDynamo Dock Port Magstripe Reader - com.magtek.idynamo
