//
//  PayPalRetailSDK.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 3/24/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

//! Project version number for PayPalRetailSDK.
extern double PayPalRetailSDKVersionNumber;

//! Project version string for PayPalRetailSDK.
extern const unsigned char PayPalRetailSDKVersionString[];

#import "PayPalRetailSDKTypeDefs.h"
#import "PayPalRetailSDKImports.h"

/**
 * Called when initializeMerchant completes
 */
typedef void (^PPRetailMerchantHandler)(PPRetailError *error, PPRetailMerchant *merchant);

/**
 * A PaymentDevice has been discovered. For further events, such as device
 * readiness, removal or the need for a software upgrade, your application should
 * subscribe to the relevant events on the device
 * parameter. Please note that this doesn't always mean the device is present. In
 * certain cases (e.g. Bluetooth)
 * we may know about the device independently of whether it's currently connected
 * or available.
 */
typedef void (^PPRetailDeviceDiscoveredEvent)(PPRetailPaymentDevice* device);
/**
 * Returned from addDeviceDiscoveredListener and used to unsubscribe from the event.
 */
typedef id PPRetailDeviceDiscoveredSignal;
typedef void (^PPRetailMerchantHandler)(PPRetailError *error, PPRetailMerchant *merchant);

/**
 * Don't use floats or doubles when money is involved. (http://bit.ly/1FlDUtl)
 * This macro makes your life a bit easier when using string based amounts.
 * For example, PAYPALNUM(@"1.25") will be an exact decimal 1.25
 */
#define PAYPALNUM(x) ([NSDecimalNumber decimalNumberWithString: x])

/**
 *
 */
@interface PayPalRetailSDK : NSObject

/**
 * This is the first call you should make to the PayPal Retail SDK (typically in application:didFinishLaunchingWithOptions:,
 * but if you are using the SDK only in certain cases or for certain customers, then at the appropriate time)
 */
+(PPRetailError*)initializeSDK;
/**
 * If for some reason you want to shutdown all SDK activity and uninitialize the SDK, call shutdownSDK. You will need to
 * call initializeSDK and initializeMerchant again to start using the SDK afterwards.
 */
+(void)shutdownSDK;

/**
 * Once you have retrieved a token for your merchant (typically from a backend server), call initializeMerchant
 * and wait for the completionHandler to be called before doing more SDK operations.
 */
+(PPRetailError*)initializeMerchant:(NSString*)merchantToken completionHandler:(PPRetailMerchantHandler)handler;

/**
 * This is the primary starting point for taking a payment. First, create an invoice, then create a transaction, then
 * begin the transaction to have the SDK listen for events and go through the relevant flows for a payment type.
 */
+(PPRetailTransactionContext*)createTransaction:(PPRetailInvoice*)invoice;

/**
 * Add a listener for the deviceDiscovered event
 * @returns PPRetailDeviceDiscoveredSignal an object that can be used to remove the listener when
 * you're done with it.
 */
+(PPRetailDeviceDiscoveredSignal)addDeviceDiscoveredListener:(PPRetailDeviceDiscoveredEvent)listener;
/**
 * Remove a listener for the deviceDiscovered event given the signal object that was returned from addDeviceDiscoveredListener
 */
+(void)removeDeviceDiscoveredListener:(PPRetailDeviceDiscoveredSignal)listenerToken;

@end
