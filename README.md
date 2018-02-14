Introduction
=================
The PayPal Here SDK enables iOS apps to process in-person credit card transactions using an assortment of [card readers](https://www.paypal.com/webapps/mpp/credit-card-reader#A39) that are capable of accepting contactless, EMV, and swipe payment methods.

Developers should use the PayPal Here SDK to get world-class payment processing with one simple integration.  Some of the main benefits include
* **Low, transparent pricing:** US Merchants pay just 2.7% per transaction (or 3.5% + $0.15 for keyed in transactions), including cards like American Express, with no additional hidden/monthly costs.
* **Safety & Security:** PayPal's solution uses encrypted swipers, such that card data is never made available to merchants or anyone else.
* **Live customer support:** Whenever you need support, we’re available to help with our customer support team.
[Visit our website](https://www.paypal.com/webapps/mpp/credit-card-reader) for more information about PayPal Here.


Supporting Materials
========================
 *  PPH SDK documentation can be found [here](https://developer.paypal.com/docs/integration/paypal-here/).
 *  Sample App: Please see and modify the sample app thats available in this repo to experiment and learn more about the SDK and it's capabilities.


Installation
==============
Our recommended installation method is Cocoapods - `pod 'PayPalHereSDKv2'`

The default installation is the Debug build but you can switch to the Release build of the PayPalHereSDK by using the Release subspec - `pod 'PayPalHereSDKv2/Release'`

As a side note, please make sure you also add `com.paypal.here.reader` to the Supported External Accessory Protocols entry of your app's `.plist` file. If you're processing with the [Mobile Card Reader](https://www.paypal.com/us/webapps/mpp/credit-card-reader-how-to/mobile-card-reader), you'll also need to add a description for Microphone usage within your `.plist` file.


Housekeeping Items
=====================
There are a few noteworthy items that should be called out. These include:
* **Key-in:** Even though there's not an example in the sample app, please know that the SDK will support this payment method should you need to implement it.
* **Server:** There will be some server-side work that needs to be done to handle the token management part of the integration. Standard Oauth2 is used for Merchant Onboarding and more information on this piece can be found [here](https://developer.paypal.com/docs/integration/paypal-here/merchant-onboarding/)
* **Marketing Toolkit:** Within this repo, you'll find downloadable marketing assets – from emails to banner ads – to help you quickly, and effectively, promote your app’s new payments functionality. 


App Review Information
======================
Only the Release build of the PayPal Here SDK is eligible for App Store release. If you submit your app for approval with the Debug build, your app will be rejected. To install the release build with Cocoapods please use:
`pod 'PayPalHereSDKv2/Release'`

When you submit your app, if you are using the [Chip Card Reader](https://www.paypal.com/us/webapps/mpp/credit-card-reader-how-to/chip-card-reader), you will need to enroll in the [Apple MFi program](https://mfi.apple.com/MFiWeb/getFAQ.action). In order to complete your enrollment, please complete the [MFi Enrollment Form](/docs/MFi-Enrollment.xls) and email it to <pph-sdk@paypal.com>. Please note that this process can take a few days to complete.

Be sure to include the following into your app store review notes:
* This iOS application uses the Bluetooth protocol "com.paypal.here.reader": PPID# 126754-0002 & PPID# 126754-0021
