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
 * DEPRECATED - Use the version that takes a completion handler and encompasses the setupMerchant call as well.
 * We hope this will lead to less cases where you think you've setup the SDK but something went wrong in the
 * call to get status and account details.
 *
 * @param merchant The merchant information including OAuth credentials
 * @param asDefault YES to securely store to keychain for future app runs, NO to keep
 * in memory copy only
 */
+(void)setActiveMerchant:(PPHMerchantInfo*)merchant asDefaultMerchant: (BOOL) asDefault DEPRECATED_ATTRIBUTE;

/*!
 * Set the currently active merchant for which all payment operations will be done.
 * If asDefault is YES, we will persist this merchant information to secure storage
 * and then when your app runs again, automatically pull it back out. If asDefault is NO
 * you're on your own and activeMerchant will be nil when you run again. To "log the
 * merchant out" you can call this with a nil merchant.
 *
 * IMPORTANT: you must wait for the completion hander to fire and for successful
 * initialization otherwise you will not be able to do transactions or other API calls
 * successfully.
 *
 * @param merchant The merchant information including OAuth credentials
 * @param asDefault YES to securely store to keychain for future app runs, NO to keep
 * in memory copy only
 */
+(void)setActiveMerchant:(PPHMerchantInfo*)merchant asDefaultMerchant: (BOOL) asDefault completionHandler: (PPHAccessCompletionHandler) completionHandler;

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
 * @param url The base URL (essentially https://stagename/) for your non-live environment.
 */
+(void)setBaseAPIURL: (NSURL*) url;

+(NSString*) sdkVersion;

@end
