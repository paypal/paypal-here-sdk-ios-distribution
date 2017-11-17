//
//  PPNativeInterface.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 3/27/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

#import "PPManticoreEngine.h"
#import "PPNativeDeviceManager.h"

@class PPAlertView;

/**
 * The native interface represents the main object exposed to the Javascript
 * layer in order to communicate with the native layer for hardware, ui, etc.
 */
@interface PPRetailNativeInterface : NSObject <
JSExport
>

-(instancetype)initWithEngine:(PPManticoreEngine*)engine;

- (JSValue*)alert:(JSValue*)options callback:(JSValue*)callback;
- (JSValue *)collectSignature:(JSValue*)options withCallback:(JSValue*)callback;
- (void)offerReceipt:(JSValue *)options withCallback:(JSValue *)callback;
- (void)getItem:(NSString *)name withDisposition:(NSString *)disposition andCallback:(JSValue*)callback;
- (void)setItem:(NSString *)name withDisposition:(NSString *)disposition value:(NSString*)value andCallback:(JSValue*)callback;

@end
