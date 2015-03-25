ios-here-sdk-dist
=================

The PayPal Here SDK enables iOS apps to interact with credit card swipers so that merchants can process in-person credit card transactions using a mobile app. The native libraries of the PayPal Here SDK enable you to:
* **Interact with PayPal Hardware** — Detect, connect to, and listen for events coming from PayPal Here audio jack-based card swipers.
* **Process Card-Present payments** — When you swipe a card through a PayPal Here swiper, card data is immediately encrypted. The encrypted package can be sent to PayPal alongside the transaction data for processing.

Full class and method documentation can be [found here](http://paypal-mobile.github.com/ios-here-sdk-dist/index.html).


Prerequisites For Using The SDK
===============================

In order to start using the PayPal Here SDK, you need the following:

1. A developer-enabled PayPal account ([sign up here](https://developer.paypal.com/webapps/developer/applications/myapps)).  This is the account you use to register your app.  You will receive an App ID & Secret to use with the SDK.
2. A PayPal Here business account ([sign up here] (https://www.paypal.com/us/webapps/mobilemerchant/page/mpa/ob/geturl?onbver=2.0&amp;country.x=US&productIntentID=mobile_payment_acceptance&referringpage=ios_sdk_github&hs=login)).  This is the account that the end merchant uses, and will be the destination account of funds received. A single app can be associated with/used by one or many merchant accounts – including the developer-enabled account.  You will receive an Access Token and Refresh URL for each merchant that grants permission to your app. (*See our [Onboarding guide](/docs/Merchant%20Onboarding.pdf) for suggestions on how to help your merchants sign up for PayPal business accounts*)
3. A PayPal Here swiper.  You can get one shipped to you when you create a business account in step (2), or via retailers like [Staples](http://www.staples.com/PayPal-Here-trade-Mobile-Card-Reader/product_1421621).
4. Apple development tools: Xcode 5.1, and an Apple developer account.

The Sample App
==============
To make it easier to see and understand how to best use the capabilities of the SDK, we’ve designed a sample/reference application.  To make the app functional, there is some minimal UI code that can be ignored – the point is to show how to use the SDK API’s.

With the Sample App, you can view code that:
* Initializes the SDK
* Authenticates the merchant
* Updates the merchant location
* Creates & adds items to an invoice
* Takes a payment with the card reader
* Takes a keyed-in card transaction
* Add a signature to finalize a payment
* Send an email/SMS receipt 


Get Started
===========
The first thing you need to do is set up your app to start using the SDK.  
* Initialize the SDK (each time the app starts) 
* Authenticate the merchant and pass the merchant’s credentials (Access Token) to the SDK [(more on PayPal oAuth)](/docs/PayPal%20Access%20oAuth.md)
* Set the merchant’s location (any time the merchant’s location changes) 
* Start monitoring the card reader for events (for card present transactions)

If you want to start with test transactions (generally a good idea), you can optionally send a selectEnvironmentWithType message to PayPalHereSDK: 
```objectivec
	[PayPalHereSDK selectEnvironmentWithType:environment_type] 
```
* *environment_type* is **ePPHSDKServiceType_Sandbox** for the Sandbox environment, or **ePPHSDKServiceType_Live** for the live environment (default).

With an authenticated merchant, it calls PayPalHereSDK.setActiveMerchant to set the merchant for which transactions will be executed. 
```objectivec
	[PayPalHereSDK setActiveMerchant:merchant withMerchantId:merchantId completionHander:handler] 
```
* *merchant* is an instance of the PPHMerchantInfo represeting a merchant object
* *merchantId* is an id for the merchant. It is defined by agreement between the back-end server and the app (not by the SDK), and must be unique among the merchants that use the back-end server and the app.
* *handler* is an id for a completion handler to be called when merchant setup is completed.

Now, monitor the card reader for events like reader connections, removals, and swipes. Invoke the  API
(SettingsViewController.m). 
```objectivec
	[[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
```

Interacting With The Card Reader
================================
Card reader interaction is established by calling:
```objectivec
    [[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
```
which will monitor for all card reader types.

Once you've begun monitoring, the SDK will start firing notification center events for relevant card events.
However, we recommend you do not monitor the notification center directly, but instead use our class that
will translate untyped notification center calls to typed delegate calls. You do this by simply storing an
instance of PPHCardReaderWatcher in your class and implementing the PPHCardReaderDelegate protocol:
```objectivec
    self.readerWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate: self];
```
The events are very simple:

```objectivec
-(void)didStartReaderDetection: (PPHReaderType) readerType; //Indicates a reader (or something else) was inserted into the headphone jack
-(void)didDetectReaderDevice: (PPHCardReaderBasicInformation*) reader; //Indicates that a PayPal reader was detected
-(void)didReceiveCardReaderMetadata: (PPHCardReaderMetadata*) metadata; //Includes additional data about the PayPal reader, like reader type and serial number
-(void)didRemoveReader: (PPHReaderType) readerType; //Indicates the reader was removed

-(void)didDetectCardSwipeAttempt; //Indicates that something (e.g. a card, a piece of paper) was swiped through the reader
-(void)didCompleteCardSwipe:(PPHCardSwipeData*)card; //Indicates a successful read of the card, with data
-(void)didFailToReadCard; //Indicates a failed read (e.g. this wasn't a credit card)
```

The first four relate to the insertion, removal and detection of the card reader, the other three are in the context of a transaction, which you must "begin" by telling the card reader manager you're ready to receive a swipe. Because some readers (namely audio jack readers) have batteries in them, you MUST be careful about when you activate the reader. In the PayPal Here app, for example, we activate the reader when there is a non-zero value in the "cart" or active order. If you have a view or step which expresses clear intent to take a charge, that's a good time to activate the reader. 


Build & Complete a Transaction
===================
In order to process a payment, there needs to be an amount to charge.  PayPal creates Invoices to represent each transaction to be paid.  Invoices can be extremely simple (a simple amount), or complex with details on item names, taxes, tips, and/or discounts.  The basic order of operations:
* Start a new invoice
* Add item data to the invoice (optional)
* Begin a purchase event and collect card data
* Collect a signature for the transaction

**Start a new invoice**

The invoice is a PPHInvoice, and doesn't need to have been saved to the PayPal backend to begin watching for card swipes. It will need to be saved before attempting a charge, but you can do this in parallel with receiving swipe data. To create an invoice, just set up a currency, add one or more items, and set tax or other information:

```objectivec
PPHInvoice *invoice = [[PPHInvoice alloc] initWithCurrency:self.currencyField.text];

[invoice addItemWithId: @"Item"
                   name: @"Purchase"
               quantity: [NSDecimalNumber one]
              unitPrice: [PPHAmount amountWithString:self.amountField.text inCurrency:self.currencyField.text].amount
                taxRate: nil
            taxRateName: nil];
```

**Add item data**

You should add details about each item on the receipt if possible. To save an invoice, just call save and provide a completion handler. Typically you would show some progress UI while doing this, unless it's being done in the background:

```objectivec
        [invoice save:^(PPHError *error) {
          // If error is non-nil, something bad happened. Else, invoice has been updated with server info
          // such as PayPal invoice id, auto-generated merchant reference number, etc.
        }
```

And then, get the invoice ready for payment:
```objectivec
// Begin the purchase and forward to payment method
 PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
 tm.ignoreHardwareReaders = NO;
 [tm beginPayment];
 tm.currentInvoice = invoice;
```
(SimpleFSPaymentDelegate.m)

**Begin a purchase event**

The PPHTransactionManager takes care of most details for you - it's even possible to take a card swipe payment without having to explicitly save the invoice or to use the card reader API to capture card events. Of course, this comes at the cost of less control over the step by step process.  If you do want to see all the card swiper events you still can create a card watcher and get all the card events while using the PPHTransactionManager at the same time.

In order to start processing card payments, use the “PPHTransactionManagerDelegate”. This protocol receives events (via the “onPaymentEvent” method) from the SDK.  In order to implement the above “onPaymentEvent” method and receive events off it, init an instance of the “PPHTransactionWatcher” class:
```objectivec
[[PPHTransactionWatcher alloc] initWithDelegate:self];
```

Second, start your payment.  Here's an example of taking a payment for a fixed amount ($5):
```objectivec
[[PayPalHereSDK sharedTransactionManager] beginPaymentWithAmount:[PPHAmount amountWithString:amountString inCurrency:@"USD"] andName:@"FixedAmountPayment"];
```

Then, wait for the user to swipe a card.   You do that by capturing the ePPHTransactionType_CardDataReceived event from the PPHTransacitonWatcher:

```objectivec
#pragma mark my PPHTransactionManagerDelegate overrides
- (void)onPaymentEvent:(PPHTransactionManagerEvent *) event {
  if(event.eventType == ePPHTransactionType_CardDataReceived) {
      NSLog(@"The transaction manager has card data!");
      // We're now clear to process the payment
  }
}
```

Now that you know the card has been captured you can ask the PPHTransactionWatcher to process the payment:
```objectivec
[[PayPalHereSDK sharedTransactionManager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe
                  withTransactionController:nil
                          completionHandler:^(PPHTransactionResponse *response) {
                              if(!record.error) {
                                  self.successfulResponse = response;
                                  NSLog(@"Payment captured successfully!  We now have the money in our account!");

if(response.isSignatureRequiredToFinalize) {
   NSLog(@"This payment requires a signature.  Let's provide one via the finalizePayment method");

}                              
                              }
                          }];
```



**Add a signature**

The PPHTransactionManager can inform you if a signature is required for the payment that is being processed (common, as signatures are usually required for transactions). When the processPayment method's completion handler is called you can check the isSignatureRequiredToFinalize member of the PPHTransactionResponse object that is provided to the completion handler. 

```objectivec
[[PayPalHereSDK sharedTransactionManager] provideSignature:self.signature.printableImage
 forTransaction:_capturedPaymentResponse.record
 completionHandler:^(PPHError *error) {
 [self showPaymentCompeleteView:_capturedPaymentResponse];
 }];
```
(SignatureViewController.m)

More Stuff to Look At
=====================
We've just scratched the surface of what's available in the PayPal Here SDK.  More detail is available in our [developer documentation](/docs/DeveloperGuide_iOS.pdf) to show other capabilities.  These include:
* **Auth/Capture:** Rather than a one-time sale, authorize a payment with a card swipe, and complete the transaction at a later time.  This is common when adding tips after the transaction is complete (e.g. at a restaurant).
* **Refunds:** Use the SDK to refund a transaction
* **Send Receipts:** You can use services through the SDK to send email or SMS receipts to customers
* **Key-in:** Most applications need to let users key in card numbers directly, in case the card's magstripe data can no longer be read.
* **CashierID:** Include your own unique user identifier to track a merchant's employee usage
* **Error Handling:** See more detail about the different types of errors that can be returned



App Review Information
======================
* This iOS application uses the Bluetooth protocol "com.paypal.here.reader": PPID# 126754-0002
* This iOS application uses the com.magtek.idynamo protocol for the Magtek iDynamo reader: PPID 103164-0003 
* This iOS application uses the jp.star-m.starpro protocol for Bluetooth printing: [SM-S220i PPID] 121976-0002 
* This iOS application uses the com.epson.escpos protocol for Bluetooth printing: MFI PPID 107611-0002
* This iOS application uses the com.bsmartdev.printer protocol for the BEE SMART, INC accessory PPID 129170-0002
* This iOS application uses the com.woosim.wspr240 protocol for the Woosim Printer PPID 122202-0001


<!--- Removing references to checkin/location management
Location Management
===================

The SDK also presents an interface for managing PayPal tab payments (aka Checkin) and the merchant locations
associated with those payments. You can create a location from scratch, or get current locations and modify
properties (such as latitude and longitude, whether it's open, and etc.). You can watch for open tabs on a
location (by polling) using the PPHLocalManager watcherForLocationId:withDelegate: method. The code below fetches
the list of locations and modifies the first location. Then, it creates and saves a location watcher, which
will monitor the location for new tabs. As of this writing, there is no automatic polling, so the update
method must be called to trigger a check for new tabs, and events will be fired as appropriate when that update
completes (error handling in the below example is omitted for readability).

```objectivec
        [[PayPalHereSDK sharedLocalManager] beginGetLocations:^(PPHError *error, NSArray *locations) {
            PPHLocation *l = [locations objectAtIndex:0];

            l.contactInfo.lineOne = @"1 International Place";
            l.contactInfo.city = @"Boston";
            l.contactInfo.state = "MA";
            l.contactInfo.countryCode = @"US";
            l.tabExtensionType = ePPHTabExtensionTypeNone;
            [l save:^(PPHError *error) {
                self.locationWatcher = [[PayPalHereSDK sharedLocalManager] watcherForLocationId:l.locationId withDelegate:self];
                [self.locationWatcher update];
            }];

        }];
```
--->

<!---
PayPal Access
=============

In order to authenticate merchants to PayPal and to issue API calls on their behalf for processing payment, you use
PayPal Access, which uses standard OAuth protocols. Basically, you send the merchant to a web page on paypal.com,
they login, and are then redirected back to a URL you control with an "oauth token." That token is then exchanged for
an "access token" which can be used to make API calls on the merchant's behalf. Additionally, a "refresh token" is
returned in that exchange that allows you to get a new access token at some point in the future without merchant
interaction. All of this is based on two pieces of data from your application - an app id and a secret. You can setup
PayPal Access and/or create an application via the [devportal](https://developer.paypal.com/). As of this writing your application will still need to be specifically enabled for the PayPal Here scope. To enable the PayPal Here scopes please contact us at <DL-PayPal-Here-SDK@ebay.com>. 
You'll note that it asks you for a Return URL, and that this Return URL must be http or https. This means you can't
redirect directly back to your mobile app after a login. But the good news is this would be a terrible idea anyways.
You never want to store your application secret on a mobile device - you can't be sure it isn't jailbroken or
otherwise compromised and once it's out there you don't have many good options for updating all your users.
So instead, you need a backend server to host this secret and control the applications usage of OAuth on
behalf of your merchants. While you can use PayPal Access as your sole point of authentication, you likely have an
existing account system of some sort, so you would first authenticate your users to your system, then send them to
PayPal and link up the accounts on their return.

The other good news is that we've included a simple sample implementation of a back end server with the SDK, written
in Node.js which most people should be able to read reasonably easily. The sample server implements four REST service
endpoints:

1. /login - a dummy version of your user authentication. It returns a "secret ticket" that can be used in place of a
password to reassure you that the person you're getting future requests from is the same person that typed in their
password to your application.
2. /goPayPal - validates the ticket and returns a URL which your mobile application can open in Safari to start
the PayPal access flow. This method specifies the OAuth scopes you're interested in, which must include the PayPal
Here scope (https://uri.paypal.com/services/paypalhere) if you want to use PayPal Here APIs.
3. /goApp - when PayPal Access completes and the merchant grants you access, PayPal will return them to this
endpoint, and this endpoint will inspect the result and redirect back to your application. First, the code calls PayPal
to exchange the OAuth token for the access token. The request to do the exchange looks like this:
```javascript
    request.post({
      url:config.PAYPAL_ACCESS_BASEURL + "auth/protocol/openidconnect/v1/tokenservice",
        auth:{
          user:config.PAYPAL_APP_ID,
          pass:config.PAYPAL_SECRET,
          sendImmediately:true
        },
        form:{
          grant_type:"authorization_code",
          code:req.query.code
        }
    }, function (error, response, body) {
    });
```
Now comes the important part. The server encrypts the access token received from PayPal using the client ticket so that
even if someone has hijacked your application's URL handler, the data will be meaningless since it wasn't the one that
sent the merchant to the PayPal Access flow anyways (this implies you chose your ticket well - the sample server doesn't
really do this because there's no backend to speak of, it's just a flat file database). Secondly, it returns a URL
to your mobile application that allows it to generate a refresh token. This URL is to the /refresh handler and
includes the refresh token issued by PayPal encrypted with an "account specific server secret." The refresh token is
never stored on the server, and is not stored in a directly usable form on the client either. This minimizes the value
of centralized data on your server, and allows you to cutoff refresh tokens at will in cases of client compromise.
4. /refresh/username/token - This handler decrypts the refresh token and calls the token service to get a new
access token given that refresh token.

To setup the server you need to setup your ReturnURL in PayPal Access to point to your instance of the sample server.
Assuming you want to test on a device, this URL needs to work on that device and on your simulator typically, meaning
you need a "real" DNS entry somewhere. Hopefully you can do this on your office router, or buy a cheap travel router
and do it there. Alternatively, you could stick the server on heroku or some such. See config.js in the sample-server
directory for the variables you need to set to run the sample server. To run the sample server, after modifying
config.js, install Node.js and run "npm install" in the sample-server directory. Then run "node server.js" and you
should see useful log messages to the console. The server advertises itself using Bonjour/zeroconf, so the sample app
should find it automatically. But again, the return URL in PayPal Access is harder to automate, so you'll need to
configure that once. One instance of the sample server can serve all your developers in theory, so it's easiest to
run it on some shared or external resource.
-->

<!--- Removing references to checkin
Opening Consumer Tabs
=====================
To checkin consumers to merchants, use the checkin.js script in the scripts directory. For example:

```
npm install
node checkin.js --help
node checkin.js -m selleraccount@paypal.com -c buyeraccount@paypal.com -i tombrady.png
```

Use -i to add an image for the buyer - this only needs to be done once. Sometimes it takes a few runs to get through,
and images tend to be very finicky in staging.
--->
