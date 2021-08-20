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
#import <PPRetailInstrumentInterface/PPRetailInstrumentationDelegate.h>
#import <PPRetailInstrumentInterface/PPRetailInstrumentationRouter.h>




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

/**
 * UntrustedNetwork event
 */
typedef void (^PPRetailUntrustedNetworkEvent)(PPRetailError* error);
/**
 * Returned from addUntrustedNetworkListener and used to unsubscribe from the event.
 */
typedef id PPRetailUntrustedNetworkSignal;

/**
 * Handler for initialize merchant.
 */
typedef void (^PPRetailMerchantHandler)(PPRetailError *error, PPRetailMerchant *merchant);

/*
  Don't use floats or doubles when money is involved. (http://bit.ly/1FlDUtl)
  This macro makes your life a bit easier when using string based amounts.
  For example, PAYPALNUM(@"1.25") will be an exact decimal 1.25
 */
#define PAYPALNUM(x) ([NSDecimalNumber decimalNumberWithString: x])

/**
 * Use PPHRetailSDKAppDelegate if you use UINavigationController in your app
 * This lets you provide the app's navigationController for the SDK to use for its UIs.
 */
@protocol PPHRetailSDKAppDelegate <NSObject>

@required
/**
 * Provide the app's navigationController
 */
- (UINavigationController *)getCurrentNavigationController;

@optional
/**
 * Reader connection UI was dismissed
 */
- (void)readerConnectionViewDismissed;
/**
 * connectToLastActiveReader connected to the last reader
 */
- (void)lastActiveReaderConnected;

@end

/**
 *
 */
@interface PayPalRetailSDK : NSObject

+ (UINavigationController *)getCurrentNavigationController;

/**
 * Use PPHRetailSDKAppDelegate if you use UINavigationController in your app.
 * This lets you provide the app's navigationController for the SDK to use for its UIs.
 */
+ (void)setRetailSDKAppDelegate:(id<PPHRetailSDKAppDelegate>)delegate;

/**
 * Used for Instrumentaion using the Instrumentation-SDK to log for various loggers.
 *
 */
+ (void)addLoggingService:(id<PPRetailInstrumentationDelegate>)logingService;


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
 * Same as logout.
 */
+ (void)shutdownSDK;

/**
 * Once you have retrieved a token for your merchant (typically from a backend server), call initializeMerchant
 * and wait for the completionHandler to be called before doing more SDK operations.
 */
+ (PPRetailError *)initializeMerchant:(NSString *)merchantToken repository:(NSString *)repository completionHandler:(PPRetailMerchantHandler)handler;

/**
 * Initialize fake merchant for testing
 */
+ (PPRetailError *)initializeFakeMerchant:(PPRetailMerchantHandler)handler;

/**
 * If you are whitelisted for offline payments
 * and you have initialized online once on the current device
 * then you can initialize the merchant offline
 */
+ (PPRetailError *)initializeMerchantOffline: (PPRetailMerchantHandler)handler;

/**
 * Once you have SdkCredentials, call initializeMerchantWithCredentials
 * and wait for the completionHandler to be called before doing more SDK operations.
 */
+ (void)initializeMerchantWithCredentials:(SdkCredential *)credentials completionHandler:(PPRetailMerchantHandler)handler;

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

#ifdef DEBUG
/**
 * @returns whether the device is being simulated or not
 */
+(BOOL)isDeviceSimulated;


/**
 * Start Simulating Payment Device - This will allow you to mock the Payment Device
 * and the server. This will only work in "DEBUG" mode
 */
+(void)startSimulationWithOptions:(PPRetailSimulationOptions *) options;

/*
 * Mock the server. You can test normal payment flows with this without connecting to actual end points.
 * Once fake server is enabled, the sdk has to be reinitialized in order to make actual payments.
 */
+ (void) enableFakeResponse;
#endif

/**
 * Add a listener for the untrustedNetwork event
 * @returns PPRetailUntrustedNetworkEvent an object that can be used to remove the listener when
 * you're done with it.
 */
+ (PPRetailUntrustedNetworkSignal)addUntrustedNetworkListener:(PPRetailUntrustedNetworkEvent)listener;

/**
 * Remove a listener for the untrustedNetwork event given the signal object that was returned from addUntrustedNetworkListener
 */
+ (void)removeUntrustedNetworkListener:(PPRetailUntrustedNetworkSignal)listenerToken;

/**
 * Capture a authorized transaction by providing authorization ID and final amount to be captured
 */
+ (void)captureAuthorizedTransaction:(NSString *_Nullable)authorizationId invoiceId:(NSString *_Nullable)invoiceId totalAmount:(NSDecimalNumber *_Nullable)totalAmount gratuityAmount:(NSDecimalNumber *_Nullable)gratuityAmount currency:(NSString *_Nullable)currency callback:(PPRetailTransactionManagerCaptureAuthorizedTransactionHandler _Nullable)callback;

/**
 * Capture a list of authorized transactions
 */
+ (void)retrieveAuthorizedTransactions:(NSDate *_Nullable)startDateTime endDateTime:(NSDate *_Nullable)endDateTime pageSize:(int)pageSize status:(NSArray *_Nullable)status callback:(PPRetailTransactionManagerRetrieveAuthorizedTransactionsHandler _Nullable)callback;
/**
 * Initialize merchant for PayPal Here app use only
 */
+ (void)initializePPHRetailMerchant:(PPHRetailMerchant *)merchant deviceId:(NSUUID *)deviceId completionHandler:(PPRetailMerchantHandler)handler;
/**
 * Initialize fake merchant for testing
 */
+ (void)initializeFakePPHRetailMerchant:(PPHRetailMerchant *)merchant completionHandler:(PPRetailMerchantHandler)handler;

/**
 * Connect to the last active reader.
 * PPHRetailSDKAppDelegate's lastActiveReaderConnected is called when the reader connects.
 * It internally invokes DeviceManager's connectToLastActiveReader
 */
+ (void)connectToLastActiveReader;

/**
 * Watch for audio readers.
 * This will show a microphone connection permission prompt on the initial call
 * Time this call such that it does not interfere with any other alerts
 * Requires a merchant, so start watching after a successful initializeMerchant
 * The audio reader may not be available to some merchants based on their location or other criteria
 */
+ (void)startWatchingAudio;

/**
 * DEPRECATED since 2.3.0021161010: endCardReaderDiscovery is no longer needed.
 */
+ (void)endCardReaderDiscovery __deprecated_msg("Starting with sdk v2.3.0021161010, endCardReaderDiscovery is a no-op.");

/**
 * DeviceManager is responsible for exposing APIs regarding the devices.
 * Currently, you can use DeviceManager to prompt the List to select the device
 * or set/get the active device.
 */
+ (PPRetailDeviceManager *)deviceManager;

/**
 * TransactionManager is a public facing facade to everything related to a Transaction.
 */
+ (PPRetailTransactionManager *)transactionManager;

/**
 * BraintreeManager is responsible for exposing APIs regarding the BrainTree interfaces
 */
+ (PPRetailBraintreeManager *)braintreeManager;

/**
 * If for some reason you want to shutdown all SDK activity and uninitialize the SDK, call logout. You will need to
 * call initializeSDK and initializeMerchant again to start using the SDK afterwards.
 * Same as shutdownSDK.
 */
+ (void)logout;

/*
 * Returns the current merchant's country code. i.e. US, JP ..etc.
 */
+ (NSString *)getMerchantCountryCode;

/**
 * Send receipt using the sdk's receipt UI
 */
+ (void)sendReceiptWithUI:(UINavigationController *)navigationController invoice:(PPRetailRetailInvoice *)invoice isEmail:(BOOL)isEmail callback:(void(^)(PPRetailError *error, NSDictionary *receiptDestination))callback;

/* Log via SDK.
 * IMPORTANT - Use this API with caution due to a potential deadlock issue.
 */
+ (void)logViaSDK:(NSString *)logLevel component:(NSString *)component message:(NSString *)message;

/**
 * Set the sdk's UI theme
 */
+ (void)setUITheme:(PPRetailUITheme)theme;

/**
 * Get the current UI theme of the sdk
 */
+ (PPRetailUITheme) getUITheme;

/**
 * Set the receipt screen orientation.
 * Use this to force the orientation to a specific value or based on the device's orientation.
 */
+ (void)setReceiptScreenOrientation:(PPRetailReceiptScreenOrientation)orientation;

/**
 * Get the orientation of the receipt screeen
 */
+ (PPRetailReceiptScreenOrientation) getReceiptScreenOrientation;

/**
 * Get the version of the PPH sdk.
 */
+ (NSString *) getSdkVersion;

/**
 * Check whether the sdk UI theme is set to light
 */
+ (BOOL)isLightTheme;

/**
 * Used by the Paypal Here app to get localized strings
 */
+ (NSString *)localizedStringNamed:(NSString *)name withDefault:(NSString *)defaultValue forTable:(NSString *)table;

@end
