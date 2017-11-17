//
//  PayPalRetailSDK.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 3/28/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "PayPalRetailSDK.h"
#import "PPRetailNativeInterface.h"
#import "PPSecureValueStorage.h"
#import "PayPalRetailSDK+Private.h"
#import "PPLocationManager.h"

NSString * const kAudioReaderPluggedIn = @"audioReaderPluggedIn";
NSString * const kAudioReaderPluggedOut = @"audioReaderPluggedOut";


@interface PayPalRetailSDK ()

@property (nonatomic,strong) PPRetailSDK *sdk;
@property (nonatomic,strong) PPRetailNativeInterface *native;
@property (nonatomic,strong) PPNativeDeviceManager *deviceManager;
@property (nonatomic,strong) PPRetailError *startupError;
@property (nonatomic, weak) id<PPHRetailSDKAppDelegate> retailSDKAppDelegate;
@property (nonatomic,strong) PPRetailMerchant *nativeMerchant;
@end

static PayPalRetailSDK *singleton;
static dispatch_once_t onceToken;

@implementation PayPalRetailSDK

+ (PPRetailError*)initializeSDK {
    dispatch_once(&onceToken, ^{
        singleton = [PayPalRetailSDK new];
        [singleton _setupJSHost];
        [singleton _startLocationServices];
    });
    return singleton.startupError;
}

+ (void)setRetailSDKAppDelegate:(id<PPHRetailSDKAppDelegate>) delegate {
    singleton.retailSDKAppDelegate = delegate;
}

+ (void)shutdownSDK {
    [singleton.deviceManager stopWatching];
    onceToken = 0;
    singleton = nil;
}

+ (PayPalRetailSDK *)singleton {
    return singleton;
}

+ (PPRetailError *)initializeMerchant:(NSString *)merchantToken completionHandler:(PPRetailMerchantHandler)handler {
    if (!singleton) {
        [PayPalRetailSDK initializeSDK];
    }
    [singleton.sdk.impl invokeMethod:@"initializeMerchant" withArguments:@[
                                                                           merchantToken,
                                                                           @"dev-stage-1",
                                                                           ^(JSValue* error, JSValue *merchant) {
        if (handler) {
            PPRetailError *nativeError = nil;
            singleton.nativeMerchant = nil;
            if (error && error.isObject) {
                nativeError = [[PPRetailError alloc] initFromJavascript:error];
            }
            if (merchant && merchant.isObject) {
                singleton.nativeMerchant = [[PPRetailMerchant alloc] initFromJavascript:merchant];
            }
            handler(nativeError, singleton.nativeMerchant);
        }
    }]];
    return nil;
}

+ (BOOL)checkIfSwiperIsEligibleForMerchant {
    return (singleton && singleton.nativeMerchant && !([singleton.nativeMerchant.currency isEqualToString: @"GBP"] || [singleton.nativeMerchant.currency isEqualToString: @"AUD"]));
}

+ (PPRetailTransactionContext *)createTransaction:(PPRetailInvoice *)invoice {
    return [singleton.sdk createTransaction:invoice];
}

+ (void)beginCardReaderDiscovery {
    if (singleton && singleton.deviceManager) {
        [singleton.deviceManager startWatching];
    }
}

+ (void)endCardReaderDiscovery {
    if (singleton && singleton.deviceManager) {
        [singleton.deviceManager stopWatching];
    }
}

+ (PPRetailDeviceManager *)deviceManager {
    return [singleton.sdk getDeviceManager];
}

+ (void)logout {
    [self endCardReaderDiscovery];
    [singleton.sdk logout];
}

+ (UINavigationController *)getCurrentNavigationController {
    return (singleton && singleton.retailSDKAppDelegate &&
            [singleton.retailSDKAppDelegate respondsToSelector:@selector(getCurrentNavigationController)]) ?
            [singleton.retailSDKAppDelegate getCurrentNavigationController] : nil;
}

- (void)_setupJSHost {
    PPManticoreEngine *engine = [PPManticoreEngine new];
    [PPRetailObject setManticoreEngine: engine];
    self.native = [[PPRetailNativeInterface alloc] initWithEngine: engine];
    self.deviceManager = [PPNativeDeviceManager new];
    __weak PayPalRetailSDK *weakSelf = self;
    engine.manticoreObject[@"ready"] = ^(JSValue *sdk) {
        weakSelf.sdk = [[PPRetailSDK alloc] initFromJavascript:sdk];
    };
    
    NSBundle *frameworkBundle = [PayPalRetailSDK sdkBundle];
    NSAssert(frameworkBundle, @"The PayPalRetailSDKResources bundle is not available. You must add this to the copy resources phase of your project.");
    NSString *jsPath = [frameworkBundle pathForResource:@"PayPalRetailSDK" ofType:@"js"];
    NSString *js = [NSString stringWithContentsOfFile:jsPath encoding:NSUTF8StringEncoding error:nil];
    NSAssert(js, @"The PayPalRetailSDKResources bundle is invalid. Please contact the PayPal Retail SDK Support team");
    
    [engine loadScript:js];
    self.startupError = nil;
}

- (void)_startLocationServices {
    [[PPLocationManager sharedManager] startWatchingLocation];
}

+ (NSBundle*)sdkBundle {
    //http://blog.flaviocaetano.com/post/cocoapods-and-resource_bundles/
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"PayPalRetailSDKResources" ofType:@"bundle"];
    
    NSBundle *frameworkBundle = [NSBundle bundleWithPath:bundlePath];
    if(!frameworkBundle){
        
        NSString *mainBundlePath = [[NSBundle mainBundle] resourcePath];
        NSString *frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"PayPalRetailSDKResources.bundle"];
        frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
        
        // TODO this is to make unit tests work, I have no idea why it's different.
        if (!frameworkBundle) {
            mainBundlePath = [[NSBundle bundleForClass:[self class]] resourcePath];
            frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"../PayPalRetailSDKResources.bundle"];
            frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
            
            if (!frameworkBundle) {
                frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"../../PayPalRetailSDKResources.bundle"];
                frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
            }
            if(!frameworkBundle){
                
                mainBundlePath = [[NSBundle bundleForClass:[singleton class]] bundlePath];
                //http://stackoverflow.com/questions/17505856/how-to-read-resources-files-within-a-framework
                NSString* frameworkBundlePath = [mainBundlePath stringByAppendingPathComponent:@"PayPalRetailSDKResources.bundle"];
                frameworkBundle = [NSBundle bundleWithPath:frameworkBundlePath];
            }
        }
    }
    return frameworkBundle;
}

+ (UIImage*)sdkImageNamed:(NSString *)imageName {
    UIImage *image;
    NSString *path = [[PayPalRetailSDK sdkBundle] pathForResource:imageName ofType:@"png"];
    if (path) {
        image = [UIImage imageWithContentsOfFile:path];
    }
    NSAssert(image != nil, @"Image not found.");
    return image;
}

+ (NSString *)getMerchantCountryCode {
    NSString *countryCode = nil;
    if (singleton) {
        countryCode = singleton.nativeMerchant.address.country;
    }
    
    return countryCode;
}

+ (void)deviceDiscovered:(JSValue *)jsDevice {
    // It's not really a PPRetailPaymentDevice* but we're all friends here (it just wants the js object)... The generated code in sdk.js is
    // for convenience, and this is the first place where it gets a little squirrely.
    PPRetailPaymentDevice *proxy = [[PPRetailPaymentDevice alloc] initFromJavascript:jsDevice];
    [singleton.sdk discoveredPaymentDevice:proxy];
}

+ (PPRetailDeviceDiscoveredSignal)addDeviceDiscoveredListener:(PPRetailDeviceDiscoveredEvent)listener {
    return [singleton.sdk addDeviceDiscoveredListener:listener];
}

+ (void)removeDeviceDiscoveredListener:(PPRetailDeviceDiscoveredSignal)listenerToken {
    [singleton.sdk removeDeviceDiscoveredListener:listenerToken];
}

+ (void)captureAuthorizedTransaction:(NSString *)authorizationId amount:(NSDecimalNumber *)amount completionHandler:(PPRetailSDKCaptureAuthorizedTransactionCallbackHandler)handler {
    [singleton.sdk captureAuthorizedTransaction:authorizationId amount:amount callback:handler];
}

+ (void)retrieveAuthorizedTransaction:(NSDate *)startTime endTime:(NSDate *)endTime pageSize:(NSInteger *)pageSize nextPageToken:(NSString *)nextPageToken completionHandler:(PPRetailSDKRetrieveAuthorizedTransactionsCallbackHandler)handler {
    [singleton.sdk retrieveAuthorizedTransactions:startTime endTime:endTime pageSize:pageSize nextPageToken:nextPageToken callback:handler];
}

+ (void)initializePPHRetailMerchant:(PPHRetailMerchant *) merchant completionHandler:(PPRetailMerchantHandler)handler {
    PPRetailError *nativeError = nil;
    if(merchant == nil) {
        nativeError = [PPRetailError alloc];
        nativeError.message = @"Merchant object cannot be null";
        handler(nativeError, nil);
    }
    
    if (!singleton) {
        [PayPalRetailSDK initializeSDK];
    }
    NSDictionary *token = @{
                            @"accessToken": merchant.credential.accessToken,
                            @"environment": merchant.credential.environment
                            };
    NSDictionary *userInfo = @{
                               @"name": merchant.userInfo.name,
                               @"given_name": merchant.userInfo.givenName,
                               @"email": merchant.userInfo.email,
                               @"businessCategory": merchant.userInfo.businessCategory,
                               @"address": @{
                                       @"street_address": merchant.userInfo.address.line1,
                                       @"locality": merchant.userInfo.address.city,
                                       @"country": merchant.userInfo.address.country,
                                       @"region": merchant.userInfo.address.state,
                                       @"postal_code": merchant.userInfo.address.postalCode,
                                       }
                               
                               };
    NSDictionary *status = @{
                             @"status": merchant.status.status,
                             @"currencyCode": merchant.status.currencyCode,
                             @"categoryCode": [NSNumber numberWithBool: merchant.status.businessCategoryExists],
                             @"paymentTypes": merchant.status.paymentTypes,
                             
                             @"cardSettings": @{
                                     @"minimum": merchant.status.cardSettings.minimum,
                                     @"maximum": merchant.status.cardSettings.maximum,
                                     @"signatureRequiredAbove": merchant.status.cardSettings.signatureRequiredAbove,
                                     @"unsupportedCardTypes": merchant.status.cardSettings.unsupportedCardTypes
                                     },
                             @"businessCategoryExists": [[PPRetailObject engine].converter toJsBool:merchant.status.businessCategoryExists],
                             };
    
    NSDictionary *pphTokenUserInfoStatus = @{
                                             @"token": token,
                                             @"userInfo": userInfo,
                                             @"status": status,
                                             @"repository": merchant.credential.repository,
                                             };
    
    JSValue *jsMerchant = [singleton.sdk.impl invokeMethod:@"setMerchant" withArguments: @[pphTokenUserInfoStatus]];
    singleton.nativeMerchant = nil;
    if (jsMerchant && jsMerchant.isObject) {
        singleton.nativeMerchant = [[PPRetailMerchant alloc] initFromJavascript:jsMerchant];
    } else {
        nativeError = [PPRetailError alloc];
        nativeError.message = @"Could not initialize merchant";
    }
    
    handler(nativeError, singleton.nativeMerchant);
}


@end
