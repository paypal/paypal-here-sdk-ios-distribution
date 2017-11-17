//
//  PayPalRetailSDK+Private.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 3/28/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//
#import "PayPalRetailSDK.h"
#import "PPRetailNativeInterface.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "PPManticoreEngine.h"
#import "PPManticoreNativeInterface.h"

@interface PayPalRetailSDK (Private)

+(PayPalRetailSDK*)singleton;

@property (nonatomic,strong) PPRetailSDK *sdk;
@property (nonatomic,strong) PPRetailNativeInterface *native;

+(NSBundle*)sdkBundle;
+(UIImage*)sdkImageNamed:(NSString *)imageName;

+(void)deviceDiscovered:(JSValue*)device;
@end

@interface PPRetailObject (Private) <
PPManticoreNativeObjectProtocol
>

@property (nonatomic, strong) JSValue *impl;

+ (void)setManticoreEngine:(PPManticoreEngine *)engine;
+ (PPManticoreEngine *)engine;

@end


#define SDK_DEBUG(c, ...) [[PayPalRetailSDK singleton].sdk logViaJs:@"debug" component:c message:[NSString stringWithFormat:__VA_ARGS__] extraData: nil]
#define SDK_INFO(c, ...)  [[PayPalRetailSDK singleton].sdk logViaJs:@"info" component:c message:[NSString stringWithFormat:__VA_ARGS__] extraData: nil]
#define SDK_WARN(c, ...)  [[PayPalRetailSDK singleton].sdk logViaJs:@"warn" component:c message:[NSString stringWithFormat:__VA_ARGS__] extraData: nil]
#define SDK_ERROR(c, ...) [[PayPalRetailSDK singleton].sdk logViaJs:@"error" component:c message:[NSString stringWithFormat:__VA_ARGS__] extraData: nil]