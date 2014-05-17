//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PayPalHereSDK/PPHCardReaderManager.h>
#import <PayPalHereSDK/PPHCardSwipeData.h>
#import <PayPalHereSDK/PPHError.h>
#import <PayPalHereSDK/PPHNetworkRequestDelegate.h>
#import <PayPalHereSDK/PPHPaymentProcessor.h>
#import <PayPalHereSDK/PPHChipAndPinEvent.h>
#import <PayPalHereSDK/PPHInvoice.h>
#import <PayPalHereSDK/PPHMerchantInfo.h>
#import <PayPalHereSDK/PPHLocalManager.h>
#import <PayPalHereSDK/PPHLoggingDelegate.h>
#import <PayPalHereSDK/PPHAccessResultType.h>
#import <PayPalHereSDK/PPHTransactionManager.h>

typedef NS_ENUM(NSInteger, PPHSDKServiceType) {
    ePPHSDKServiceType_Live,
    ePPHSDKServiceType_Sandbox
};

typedef void (^PPHAccessCompletionHandler)(PPHAccessResultType status, PPHAccessAccount* account, NSDictionary* extraInfo);

@class PPHAccessController;
@protocol PPHAnalyticsDelegate;

/*!
 * The main object through which you can interact with PayPal and associated hardware devices
 * such as card readers and chip & pin devices.
 */
@interface PayPalHereSDK : NSObject

/*
 * Shared service providers for single-use-per-app type of capabilities
 */

/*!
 * The interface to interact with the card reader
 */
+(PPHCardReaderManager*) sharedCardReaderManager;
/*!
 * The interface to interact with checkin services and merchant locations
 */
+(PPHLocalManager*) sharedLocalManager;
/*!
 * The interface to process payments with card swipe, keyed in/scanned, and checkins
 */
+(PPHPaymentProcessor*) sharedPaymentProcessor;
/*!
 * A helper to establish OAuth credentials on behalf of your application for a merchant.
 */
+(PPHAccessController*) sharedAccessController DEPRECATED_ATTRIBUTE;

/*!
 * A way to do payments & refunds in a stateful way
 */
+(PPHTransactionManager*) sharedTransactionManager;


/*!
 * Should you wish to handle your own network requests, you can set this singleton
 * which the PayPal Here SDK will call whenever a network request needs to go out.
 * @param delegate an object implementing PPHNetworkRequestDelegate which will be in charge of executing requests
 */
+(void)setNetworkDelegate: (id<PPHNetworkRequestDelegate>) delegate;
/*!
 * The current network request delegate.
 */
+(id<PPHNetworkRequestDelegate>)networkDelegate;
/*!
 * If you handle your own network requests, you should update the progress of those requests
 * via this method so that various SDK features (such as reader software updates) can report
 * overall progress back to you. This method is meant to allow you to get more precise about
 * progress than is likely possible - so for example you could say a network request consists
 * of connecting, uploading the request info, and downloading (3 totalSteps), and could assign
 * estimated relative durations of each of those to be used in computing the total step units.
 * But for the rest of us mortals, you'll probably just say it's 1 step and the percentage is
 * the percentage of the download that's completed.
 *
 * @param originalRequest The request as originally passed to your network delegate. If you
 *      "rewrite" the request, you need to keep the old one around to properly inform us of
 *      progress.
 * @param currentStep The 1-based index of the step currently executing (e.g. it doesn't make
 *      sense to be on the 0th step.
 * @param totalSteps The count of the total number of steps required to execute the request.
 *      Must be at least 1.
 * @param wholeNumberCurrentPercentage a number between 0 and 100 expressing how much of the
 *      current step is completed.
 * @param wholeNumberTotalPercentage a number between 0 and 100 expressing how much of the
 *      total process is completed.
 */
+(void)reportNetworkRequestProgress: (NSURLRequest*)originalRequest
                        currentStep: (NSInteger) currentStep
                         totalSteps: (NSInteger) totalSteps
              currentStepPercentage: (NSInteger) wholeNumberCurrentPercentage
        totalStepPercentageEstimate: (NSInteger) wholeNumberTotalPercentage;

/*!
 * Should you wish to handle your own analytics, you can set this singleton.
 * Be warned if you don't also let us do our own analytics we will not be able
 * to help diagnose aggregate issues for our SDK in your application.
 * @param delegate an object implementing PPHAnalyticsDelegate which will be in charge of reporting events
 */
+(void)setAnalyticsDelegate: (id<PPHAnalyticsDelegate>) delegate;
/*!
 * The current analytics delegate.
 */
+(id<PPHAnalyticsDelegate>)analyticsDelegate;

/*!
 * Should you wish to receive internal log messages, set this delegate. See
 * PPHLogingDelegate for a warning about performance impact.
 * @param delegate an object implementing one or more methods of
 * the PPHLoggingDelegate
 */
+(void)setLoggingDelegate: (id<PPHLoggingDelegate>) delegate;
/*!
 * The current logging delegate or nil.
 */
+(id<PPHLoggingDelegate>)loggingDelegate;

/*!
 * The currently active merchant account
 */
+(PPHMerchantInfo*)activeMerchant;


/*!
 * Set the currently active merchant for which all payment operations will be done.
 * We will persist this merchant information to secure storage.  When your app runs
 * again and you call setActiveMerchant with a merchantId we've seen before we'll 
 * automatically check the saved merchant info for that merchantId.  If you pass in 
 * a nil or sparsely filled out merchant object we'll use the values we pulled from
 * storage.
 *
 * IMPORTANT: you must wait for the completion hander to fire and for successful
 * initialization otherwise you will not be able to do transactions or other API calls
 * successfully.
 *
 * @param merchant The merchant information including OAuth credentials
 * @param merchantId a value which we'll use to uniquely identify this merchant on this device so
 * we can save/fetch this specific merchant's information from local secure storage.
 * If more than one merchant logs into this system you should make sure you provide
 * different values.  This id belongs to the app and is not generated by paypal
 * nor sent down to the service.
 * @param completionHandler The handler to be called when the merchant setup has completed
 * (setup includes a call to the server to verify the token and retrieve user information)
 */

+(void)setActiveMerchant:(PPHMerchantInfo*)merchant withMerchantId:(NSString*)merchantId completionHandler: (PPHAccessCompletionHandler) completionHandler;

/*!
 * Returns YES if we have the access we need to device location information
 * (we ask for significant location changes so long as a transaction is in progress,
 * or for general location updates if the device does not support significant updates).
 *
 * You will not be able to complete transactions without location services enabled.
 */
+(BOOL)hasLocationAccess;

/*!
 * To allow you fine grained control over location access prompts, you can call this method
 * explicitly. It doesn't do anything more than ask for location, so you can certainly do
 * that yourself and get control of the messaging, but this method is here for your
 * convenience.
 */
+(BOOL)askForLocationAccess;

/*!
 * For TEST purposes, you can set the service URL used for requests in the PayPal Here SDK
 *
 * DEPRECATED: Use the selectEnvironmentWithType method which allows selection between available
 * services.
 *
 * @param url The base URL (essentially https://stagename/) for your non-live environment.
 */
+(void)setBaseAPIURL: (NSURL*) url DEPRECATED_ATTRIBUTE;

/*!
 * Used to select between PPHSDKServiceTypes - currently just Live or Sandbox.  
 * 
 * By default the SDK will run against Live, no need to call this method if you'd
 * like to use the Live service.
 *
 * However, if you want the SDK to run against PayPal's Sandbox environment,
 * or you wish to point the SDK back at Live, you can use this method.
 *
 * @param serviceType The service to connect to.
 */
+(void)selectEnvironmentWithType: (PPHSDKServiceType) serviceType;

/*!
 * The version of the SDK currently in use
 */
+(NSString*) sdkVersion;

/*!
 * The partner referrer code.
 */
+(NSString*) referrerCode;

/*!
 * Set the Partner Referrer code that is obtained after sigining up with PayPalHere.
 * NOTE: If the value is set in here, it would be automatically set within the invoice.
 * If not, you would need to feed in same the information within the invoice object.
 * @param referrerCode the referrer code that is obtained once a partner registers with PayPalHere.
 */
+(void) setReferrerCode: (NSString*) referrerCode;

@end
