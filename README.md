Introduction
=================
The PayPal Here SDK enables iOS apps to process in-person credit card transactions using an assortment of [card readers](https://www.paypal.com/webapps/mpp/credit-card-reader#A39) that are capable of accepting contactless, EMV, and swipe payment methods.

Developers should use the PayPal Here SDK to get world-class payment processing with one simple integration.  Some of the main benefits include
* **Low, transparent pricing:** US Merchants pay just 2.7% per transaction (or 3.5% + $0.15 for keyed in transactions), including cards like American Express, with no additional hidden/monthly costs.
* **Safety & Security:** PayPal's solution uses encrypted swipers, such that card data is never made available to merchants or anyone else.
* **Live customer support:** Whenever you need support, we’re available to help with our customer support team.
[Visit our website](https://www.paypal.com/webapps/mpp/credit-card-reader) for more information about PayPal Here.
* **Partner program:** Please [contact us](https://www.paypal-business.com/SDKdeveloperinterestregistration) for any partnership program questions or opportunities.

> **Note:** From 1 July 2021 AEST, PayPal Here services (including both the credit card reader devices and the PayPal Here App) will no longer be available in Australia. This means you will not be able to accept payments through PayPal Here with the credit card reader device or via the PayPal Here App from that date. We have also ceased the sale of new PayPal Here credit card reader devices. If you are looking for a card payment solution, please see [here](https://www.paypal.com/merchantapps/appcenter/acceptpayments). If you are an existing PayPal Here customer and have any questions, please click [here](https://www.paypal.com/au/webapps/mpp/paypal-here-faq?locale.x=en_AU).


Supporting Materials
========================
 *  PPH SDK documentation can be found [here](https://developer.paypal.com/docs/integration/paypal-here/).
 *  PPH SDK class reference can be found [here](http://paypal.github.io/paypal-here-sdk-ios-distribution/).
 *  Sample App: Please see and modify the sample app thats available in this repo to experiment and learn more about the SDK and it's capabilities.


Installation
==============
Our recommended installation method is Cocoapods - `pod 'PayPalHereSDKv2'`

The default installation is the Debug build but you can switch to the Release build of the PayPalHereSDK by using the Release subspec - `pod 'PayPalHereSDKv2/Release'`

As a side note, please make sure you also add `com.paypal.here.reader` to the Supported External Accessory Protocols entry of your app's `.plist` file. If you're processing with the [Mobile Card Reader](https://www.paypal.com/us/webapps/mpp/credit-card-reader-how-to/mobile-card-reader), you'll also need to add a description for Microphone usage within your `.plist` file.


Housekeeping Items
=====================
There are a few noteworthy items that should be called out. These include:
* **Auth/Capture:** Please note that auth/capture processing is currently only available for the US and UK.
* **Key-in:** Even though there's not an example in the sample app, please know that the SDK will support this payment method should you need to implement it.
* **Server:** There will be some server-side work that needs to be done to handle the token management part of the integration. Standard Oauth2 is used for Merchant Onboarding and more information on this piece can be found [here](https://developer.paypal.com/docs/integration/paypal-here/merchant-onboarding/)
* **Marketing Toolkit:** Within this repo, you'll find downloadable marketing assets – from emails to banner ads – to help you quickly, and effectively, promote your app’s new payments functionality. 
* **SDK 1.6:** All new integrations should use this v2 version of the PayPal Here SDK. Existing partners looking for prior versions of this SDK are recommended to update to this version, but can find [version 1.6 here](https://github.com/paypal/paypal-here-sdk-ios-distribution/tree/PayPalHereSdkv1.6).


App Review Information
======================
Only the Release build of the PayPal Here SDK is eligible for App Store release. If you submit your app for approval with the Debug build, your app will be rejected. To install the release build with Cocoapods please use:
`pod 'PayPalHereSDKv2/Release'`

When you submit your app, if you are using the [Chip Card Reader](https://www.paypal.com/us/webapps/mpp/credit-card-reader-how-to/chip-card-reader), you will need to enroll in the [Apple MFi program](https://mfi.apple.com/MFiWeb/getFAQ.action). In order to complete your enrollment, please complete the [MFi Enrollment Form](/docs/MFi-Enrollment.xls) and email it to <pph-sdk@paypal.com>. Please note that this process can take a few days to complete.

Be sure to include the following into your app store review notes:
* This iOS application uses the Bluetooth protocol "com.paypal.here.reader": PPID# 126754-0002 & PPID# 126754-0026


Keep the app connected to the reader when the app goes to background
====================================================================

Here’s what will make the Bluetooth readers stay connected to a sample/partner app when the app is backgrounded (till the OS decides to kill the app)

Project -> Capabilities -> Background Modes -> ON 

Enable/Check
* External accessory communication
* Uses Bluetooth LE accessories
* Act as a Bluetooth LE accessory

[License](LICENSE.md)
=======
