Native Shims for Retail SDK
===========================

This directory contains the native implementations to expose the PayPal Retail SDK functionality on various target
platforms. Currently, this includes:

* Windows XP - using .Net 4.0 and Jint along with HIDLibrary and 32Feet for USB and Bluetooth respectively.
* Windows Vista/7/8 - using .Net 4.5 and ClearScript V8 along with HIDLibrary and 32Feet
* Windows 8.1 Desktop - using .Net 4.5 and Jint (because of app store limitations) and native Windows USB/Bluetooth APIs, plus the Windows Point of Sale APIs for magnetic swipers
* Windows 8.1 Phone - using .Net 4.5 and Jint, native USB/Bluetooth APIs
* Android 19 or above - using Rhino and native USB/Bluetooth functions
* iOS 7+ - Using JavaScriptCore and native BT/EAAccessory frameworks
* Mac OS X - Using JavaScriptCore with QRSerial and native USB/Bluetooth
* Chrome - Run as a Chrome app using Google's USB and Bluetooth abstractions, HTML5 UI and of course the Chrome V8 Javascript engine. This turns out to be my personal favorite for debugging because it's Javascript [turtles all the way down](http://en.wikipedia.org/wiki/Turtles_all_the_way_down).
* node - node.js with node-hid and node-bluetooth. This will be very useful for fully automated certification

The Native Contract
===================
Code generation is used to create native classes and other primitives from the Javascript SDK. The intent is that there is very little state or intelligence in native - for example all property lookups from native simply go down to the Javascript immediately. When manipulating data objects, mostly the native shim is just translating types back and forth and hooking up method calls to the right JS and Native entities. On a higher level, the native shim is responsible for doing various things Javascript can't do:

* Logging during debugging (in release it should be handled in JS though we haven't sorted out how to get log messages from native down into JS for this)
* Discovering and connecting to hardware devices
* Delayed execution (e.g. setTimeout)
* Persistent retrieval and storage of key value pairs
* Making network requests (a single "ajax" function that can perform all HTTP transactions)
* Providing the following user interface components
    + Alerts with zero or more buttons, a title and message, and/or a progress indicator
    + A signature view on which a consumer can provide a signature for a transaction
    + A receipt selection view/flow where a consumer can choose to receive a receipt by email or text
* Providing GPS information

WARNING
=======

**Certain JS VMs do NOT support variable argument native callbacks (such as ClearScript on Windows Desktop). As a result,
you MUST pass all the arguments specified for the function, using null or undefined for missing arguments.**

Alerts
======
```
  manticore.alert({title:'Foo',showActivity:true,cancel:'Cancel!'}, (alertInstance, index) => {
    // Index is the button index
  });
```
The contract for alerts assumes a single alert can be present at any given time. That alert must be dismissed by the
Javascript at some point, OR if a SECOND alert call is made while an alert is up, dismiss is called implicitly for that
first alert. This means that any "stacking" of alerts must be done in Javascript as native will not have to think about
that sort of state management. It also means that calling manticore.alert while an existing alert is showing is equivalent to "update" of all aspects of the alert, and the native implementations should prevent flicker.

An alert is a modal view (e.g. blocks interaction with the hosting app) with any or all of the following features:

* A short title
* A longer-but-still-short message
* An activity indicator such as a spinner or indeterminate progress bar
* A cancel button (visually treated as the default button)
* Zero or more arbitrary other buttons

Whenever a button is pressed, the callback passed the 0 based index of the pressed button. The callback is in charge of
dismissing the alert, either after a button is pressed or when a background operation completes. This keeps with the
spirit of keeping state and smarts OUT of the native code and in the Javascript.

Key Value Pairs
===============
The native layer must manage four groups of storage for Javascript. get/set item are always asynchronous and there are
no return values for these functions.

* 'S' - (Secure) - Values that should be kept in secure storage because they contain sensitive information. These values
must be relatively small (< 1MB for example) as they are likely to be in some string-based storage. We haven't had a
case for large value secure storage, but if we do we should evaluate storing a key in secure and offering native crypto
helpers.
* 'V' - (Values) - Values that are small strings and can be stored wherever is convenient
* 'B' - (Blob) - Large values (usually passed as base64 encoded buffer) that should be stored on a file system or similar
* 'E' - (Encrypted Blob) - Large values that may contain sensitive information

```
manticore.setItem('SecretValueKeyName', 'S', 'This value is a super duper secret', (e) => {
  // At this point the item has been stored, or error e has occurred
});
manticore.getItem('SecretValueKeyName', 'S', (error, value) => {
  assert.equals('This value is a super duper secret', value);
});
```

Payment Devices
===============

Native is in charge of managing data pipes between hardware devices and the Retail SDK. The native implementation must
SUPPLY the following methods:

* connect(callback) - Attempt a connection to the device and invoke the callback when the connection succeeds (with no arguments) or fails (with an error as the first argument)
* send(base64Data||{data,len,offset}, callback) - Send either a blob of base64 data or a portion of a blob of base64 data. The latter is provided to allow efficient partial sends without unpacking and repacking the base64 string. Standard callback invocation - error as first argument if any error occurred.
* isConnected - returns true if the device is currently connected, false otherwise
* disconnect(callback) - Attempt to disconnect from the device, standard callback invocation. A subsequent call to `connect(callback)` is expected to eventually succeed (without any manual intervention like rebooting the device, unplugging from USB port, etc.) and take the device back to a state where it can start accepting commands from SDK.

The native implementation may rely on or call the following methods in the JS device:

* received(base64Data) - When data has been received from the device
* onDisconnected(error) - When the device has disconnected

