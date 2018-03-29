//
//  PayPalRetailSDK.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 3/24/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PayPalRetailSDKTypeDefs.h"
#import "PayPalRetailSDKImports.h"
#import "PPHRetailMerchant.h"
#import "PPRetailError.h"

//! Project version number for PayPalRetailSDK.
extern double PayPalRetailSDKVersionNumber;

//! Project version string for PayPalRetailSDK.
extern const unsigned char PayPalRetailSDKVersionString[];

/**
 * Called when initializeMerchant completes
 */
typedef void (^PPRetailMerchantHandler)(PPRetailError *error, PPRetailMerchant *merchant);

extern NSString * const kAudioReaderPluggedIn;
extern NSString * const kAudioReaderPluggedOut;
extern NSString * const kAudioReaderSwipeDidFail;
extern NSString * const kAudioReaderSwipeDetected;

/**
 * Is the constant used for notifying others of the event that the receipt options screen finished loading.
 */
extern NSString* const kReceiptOptionsFinishedLoading;

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

@protocol PPHRetailSDKAppDelegate <NSObject>

@required
- (UINavigationController *)getCurrentNavigationController;

@optional
- (void)readerConnectionViewDismissed;
- (void)lastActiveReaderConnected;

@end

/**
 *
 */
@interface PayPalRetailSDK : NSObject

+ (UINavigationController *)getCurrentNavigationController;

+ (void)setRetailSDKAppDelegate:(id<PPHRetailSDKAppDelegate>)delegate;

/**
 * This is the first call you should make to the PayPal Retail SDK (typically in application:didFinishLaunchingWithOptions:,
 * but if you are using the SDK only in certain cases or for certain customers, then at the appropriate time)
 */
+ (PPRetailError *)initializeSDK;

/**
 * Use this call to determine whether the current merchant is elegible to use a swiper
 */
+ (BOOL)checkIfSwiperIsEligibleForMerchant;

/**
 * If for some reason you want to shutdown all SDK activity and uninitialize the SDK, call shutdownSDK. You will need to
 * call initializeSDK and initializeMerchant again to start using the SDK afterwards.
 */
+ (void)shutdownSDK;

/**
 * Once you have retrieved a token for your merchant (typically from a backend server), call initializeMerchant
 * and wait for the completionHandler to be called before doing more SDK operations.
 */
+ (PPRetailError *)initializeMerchant:(NSString *)merchantToken repository:(NSString *)repository completionHandler:(PPRetailMerchantHandler)handler;

/**
 * Once you have SdkCredentials, call initializeMerchantWithCredentials
 * and wait for the completionHandler to be called before doing more SDK operations.
 */
+ (void)initializeMerchantWithCredentials:(SdkCredential *)credentials completionHandler:(PPRetailMerchantHandler)handler;

/**
 * This is the primary starting point for taking a payment. First, create an invoice, then create a transaction, then
 * begin the transaction to have the SDK listen for events and go through the relevant flows for a payment type.
 */
+ (PPRetailTransactionContext *)createTransaction:(PPRetailInvoice *)invoice __attribute__((deprecated("Deprecated since v2.0.0. Use transactionManager")));

/**
 * Add a listener for the deviceDiscovered event
 * @returns PPRetailDeviceDiscoveredSignal an object that can be used to remove the listener when
 * you're done with it.
 */
+ (PPRetailDeviceDiscoveredSignal)addDeviceDiscoveredListener:(PPRetailDeviceDiscoveredEvent)listener;

/**
 * Remove a listener for the deviceDiscovered event given the signal object that was returned from addDeviceDiscoveredListener
 */
+ (void)removeDeviceDiscoveredListener:(PPRetailDeviceDiscoveredSignal)listenerToken;

/**
 * Capture a authorized transaction by providing authorization ID and final amount to be captured
 */
+ (void)captureAuthorizedTransaction:(NSString *_Nullable)authorizationId invoiceId:(NSString *_Nullable)invoiceId totalAmount:(NSDecimalNumber *_Nullable)totalAmount gratuityAmount:(NSDecimalNumber *_Nullable)gratuityAmount currency:(NSString *_Nullable)currency callback:(PPRetailTransactionManagerCaptureAuthorizedTransactionHandler _Nullable)callback;

+ (void)retrieveAuthorizedTransactions:(NSDate *_Nullable)startDateTime endDateTime:(NSDate *_Nullable)endDateTime pageSize:(int)pageSize status:(NSArray *_Nullable)status callback:(PPRetailTransactionManagerRetrieveAuthorizedTransactionsHandler _Nullable)callback;

+ (void)initializePPHRetailMerchant:(PPHRetailMerchant *)merchant completionHandler:(PPRetailMerchantHandler)handler;

+ (void)connectToLastActiveReader;

/**
 * Watch for audio readers.
 * This will show a microphone connection permission prompt on the initial call
 * Time this call such that it does not interfere with any other alerts
 * Requires a merchant, so start watching after a successful initializeMerchant
 * The audio reader may not be available to some merchants based on their location or other criteria
 */
+ (void)startWatchingAudio;

+ (void)endCardReaderDiscovery;

+ (PPRetailDeviceManager *)deviceManager;

+ (PPRetailTransactionManager *)transactionManager;

+ (void)logout;

/*
 * Returns the current merchant's country code. i.e. US, JP ..etc.
 */
+ (NSString *)getMerchantCountryCode;

+ (NSString *)localizedStringNamed:(NSString *)name withDefault:(NSString *)defaultValue forTable:(NSString *)table;

+ (void)sendReceiptWithUI:(UINavigationController *)navigationController invoice:(PPRetailRetailInvoice *)invoice isEmail:(BOOL)isEmail callback:(void(^)(PPRetailError *error, NSDictionary *receiptDestination))callback;

/* Log via SDK.
 * IMPORTANT - Use this API with caution due to a potential deadlock issue.
 */
+ (void)logViaSDK:(NSString *)logLevel component:(NSString *)component message:(NSString *)message;
@end
