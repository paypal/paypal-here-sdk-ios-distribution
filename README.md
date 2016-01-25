Introduction
=================

The PayPal Here SDK enables iOS apps to process in-person credit card transactions using Contactless/EMV chip card readers or magstipe swipers. The native libraries of the PayPal Here SDK enable you to:

* **Interact with PayPal Hardware** — Detect, connect to, and listen for events coming from PayPal Here audio jack-based card swipers.
* **Process Card-Present payments** — When you swipe a card through a PayPal Here swiper, card data is immediately encrypted. The encrypted package can be sent to PayPal alongside the transaction data for processing.

Developers should use the PayPal Here SDK to get world-class payment process with extremely simple integration.  Some of the main benefits include
* **Low, transparent pricing:** US Merchants pay just 2.7% per transaction (or 3.5% + $0.15 for keyed in transactions), including cards like American Express, with no additional hidden/monthly costs.
* **Safety & Security:** PayPal's solution uses encrypted swipers, such that card data is never made available to merchants or anyone else.
* **Live customer support:** Whenever you need support, we’re available to help with our customer support team.
[Visit our website](https://www.paypal.com/webapps/mpp/credit-card-reader) for more information about PayPal Here.


As an alternative to the SDK, a developer can also use a URI framework that lets one app (or mobile webpage) link directly to the PayPal Here app to complete a payment.  Using this method, the merchant will tap a button or link in one app, which will open the pre-installed PayPal Here app on their device, with the PayPal Here app pre-populating the original order information, collect a payment (card swipe) in the PayPal Here app, and return the merchant to the original app/webpage. This is available for US, UK, Australia, and Japan for iOS & Android.  See the [Sideloader API](https://github.com/paypal/here-sideloader-api-samples) on Github.


The supporting materials
========================
 *  API documentation can be [found here](http://paypal-mobile.github.com/ios-here-sdk-dist/index.html).
 *  Sample Apps: Please see and modify the sample app availble in this repo to experiment and learn more about the SDK and it's capabilities.
 *  If you are migrating from a previous implementation (v 1.5) of the PayPal Here SDK please see our [migration guide](/docs/1.5-1.6_MigrationGuide.md).


Installation
==============

Our recommended installation method is Cocoapods 
`pod 'PayPalHereSDK'`

You can also switch to the Release or 'No Hardware' builds of the PayPalHereSDK by using the different pod subspecs
`pod 'PayPalHereSDK/Release'`

If you prefer a manual integration you can file the steps in the [project configuration guide](/docs/ProjectConfiguration.md) to properly set up your application.

Authentication
===============================

1. Set up a PayPal developer account ([sign up here](https://developer.paypal.com/developer/applications/)) and configure an application to be used with the PayPal Here SDK.  Refer to the [PayPal Here SDK integration Document](https://developer.paypal.com/docs/integration/paypal-here/) for information on how to properly configure your app.

2. Deploy and configure the [Retail SDK Authentication Server](https://github.com/djMax/paypal-retail-node) OR manually negotiate the [PayPal oAuth2 flow](https://developer.paypal.com/docs/integration/direct/paypal-oauth2/) to obtain the tokens required for login.

See our [Merchant Onboarding Guide](docs/Merchant%20Onboarding%20Guide.pdf) for suggestions on how to help your merchants sign up for PayPal business accounts and link them in your back-office software.

SDK Initialization
==================

* Configure the environment if you wish to use sandbox, when using _mastripe swipers_.  Consult the [sandbox overview](https://developer.paypal.com/docs/classic/lifecycle/sb_overview/) for more information about the PayPal sandbox environment.

```objc
[PayPalHereSDK selectEnvironmentWithType:ePPHSDKServiceType_Sandbox];
```

* Setup the SDK merchant with your credentials.

```objc
// Either with raw tokens...
[PayPalHereSDK setupWithCredentials:refreshUrl:tokenExpiryOrNil:thenCompletionHandler:];

// Or by digesting the response from paypal-retail-node...
[PayPalHereSDK setupWithCompositeTokenString:thenCompletionHandler:];
```

Invoices
================================

Invoices in the PayPal Here SDK define the order which we are interacting with using the PayPal APIs. They provide synchronization with the website, total calculation and many more powerful features.

To take a payment we must first create an invoice which can be as simple or complex as your use case demands. The simplest use case is to create an invoice for a single non-itemized amount:

```objc
PPHInvoice *myOneDollarInvoice = [[PPHInvoice alloc] initWithItem:@"Total" forAmount:[PPHAmount amountWithDecimal:[NSDecimalNumber one]]];
```

Taking Payments
================================

The PayPal Here SDK offers several different ways to accept payments. This document will only cover the use of the "UI" methods of `PPHTransactionManager`. These methods handle many aspects of the payment process for you automatically including:

* Reader connection and activation
* Listening for card events
* Complicated EMV flows
* Signature entry UI and transmission
* Receipt destination UI and transmission

The steps to execute a card present transaction using these APIs are simple:

1. Implement the `PPHTransactionControllerDelegate` protocol
2. Call `[[PayPalHereSDK sharedTransactionManager] beginPaymentUsingUIWithInvoice:transactionController:];` to enable the card reader, begin watching the invoice, and begin receiving updates on the `PPHTransactionControllerDelegate` you implemented.
3. Call `[[[PayPalHereSDK sharedTransactionManager] activateReaderForPayments:]` if and when you wish to enable NFC payments.
4. When the reader detects a card has been presented `userDidSelectPaymentMethod:;` will be called on your `PPHTransactionControllerDelegate`. You may use this opportunity to make any changes before authorizing the payment (e.g. asking a user for a tip).
5. Call `[[PayPalHereSDK sharedTransactionManager] processPaymentUsingUIWithPaymentType:completionHandler:]` to authorize the payment.
6. Reset the navigation stack when your completion handler is called.

A sample implementation of this would look like:

```objc
////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation MyTransactionViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
 
    PPHInvoice *sampleInvoice = [[PPHInvoice alloc] initWithItem:@"Falcon Punch!" forAmount:[PPHAmount amountWithString:@"1.00"]];
    [[PayPalHereSDK sharedTransactionManager] beginPaymentUsingUIWithInvoice:sampleInvoice
                                                       transactionController:self];
}


- (void)userDidSelectPaymentMethod:(PPHPaymentMethod) paymentOption {
    [[PayPalHereSDK sharedTransactionManager] processPaymentUsingUIWithPaymentType:paymentOption
                                                                 completionHandler:^(PPHTransactionResponse *response) {
                                                                     if (response.error) {
                                                                         NSLog(@"Transaction failed!");
                                                                     } else {
                                                                         NSLog(@"Transaction successful!");
                                                                     }
                                                                     
                                                                     [self.navigationController popToViewController:self animated:YES];
                                                                 }];
}

- (void)userDidSelectRefundMethod:(PPHPaymentMethod) refundOption {
    
}

- (UINavigationController *)getCurrentNavigationController {
    return self.navigationController;
}

@end
```

You may implement the various optional methods of `PPHTransactionControllerDelegate` to influence the payment flow where appropriate.

The approach for taking a refund is very similar.


Card Readers
================================

Although `PPHTransactionManager` is capable of managing card readers by itself there may be times when you require more information about the card reader or more granular control over card readers. This functionality is provided by `PPHCardReaderManager`.

**Card Reader Metadata**

Information on past and present card reader types, capabilities, names, and more can be accessed in the form of `PPHCardReaderMetadata` objects.

```objc
NSLog(@"The active card reader's type is: %d", [[PayPalHereSDK sharedCardReaderManager] activeReader].readerType);

NSLog(@"The last bluetooth reader that was available was named %@", [[PayPalHereSDK sharedCardReaderManager] lastAvailableReaderOfType:ePPHReaderTypeChipAndPinBluetooth].friendlyName);

NSLog(@"The active card reader has %d%% battery remaining.", [[PayPalHereSDK sharedCardReaderManager] activeReader].batteryInfo.level);
```

**Card Reader Events**

If you wish to monitor the events of a card reader such as connection, metadata updates, and magstripe interactions doing so is as simple as implementing the various `PPHCardReaderDelegate` protocol methods and allocating a `PPHCardReaderWatcher`.

```objc
@implementation MyCardReaderDelegate

- (instancetype)init {
    if (self = [super init]) {
        self.cardReaderWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
    }

    return self;
}

-(void)didDetectReaderDevice:(PPHCardReaderMetadata *)reader {
    NSLog(@"Reader with name %@ detected!", reader.friendlyName);
}


@end
```

More Stuff to Look At
=====================
There is a lot more available in the PayPal Here SDK.  More detail is available in our [developer documentation](/docs/DeveloperGuide_iOS.pdf) to show other capabilities.  These include:
* **Auth/Capture:** Rather than a one-time sale, authorize a payment with a card swipe, and complete the transaction at a later time.  This is common when adding tips after the transaction is complete (e.g. at a restaurant).
* **Refunds:** Use the SDK to refund a transaction
* **Send Receipts:** You can use services through the SDK to send email or SMS receipts to customers
* **Key-in:** Most applications need to let users key in card numbers directly, in case the card's magstripe data can no longer be read.
* **CashierID:** Include your own unique user identifier to track a merchant's employee usage
* **Error Handling:** See more detail about the different types of errors that can be returned
* **Marketing Toolkit:** Downloadable marketing assets – from emails to banner ads – help you quickly, and effectively, promote your app’s new payments functionality. 



App Review Information
======================
Only the release build of the PayPal Here SDK is eligible for App Store release. If you submit your app for approval with the debug build, your app will be rejected. To install the release build with Cocoapods please use:
`pod 'PayPalHereSDK/Release'`

When you submit your app, you may need to enroll to in the [Apple MFi program](https://mfi.apple.com/MFiWeb/getFAQ.action). In order to complete your enrollment, please complete the [MFi Enrollment Form](/docs/MFi-Enrollment.xls) and email it to <pph-sdk@paypal.com>.

Be sure to include the following into your app store review notes:
* This iOS application uses the Bluetooth protocol "com.paypal.here.reader": PPID# 126754-0002 & PPID# 126754-0021
* This iOS application uses the com.magtek.idynamo protocol for the Magtek iDynamo reader: PPID 103164-0003
