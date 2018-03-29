//
//  PPManticoreNativeInterface.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 3/27/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@class PPManticoreEngine;


/**
 * Generated classes implement this protocol which tells us to pass
 * the JSValue across the boundary instead of the object instance.
 */
@protocol PPManticoreNativeObjectProtocol <NSObject>

@required
-(JSValue*)impl;
+(PPManticoreEngine*)engine;
+(Class)nativeClassForObject:(JSValue*)value;
-(id)initFromJavascript:(JSValue*)value;

@end


/**
 * This class makes event listeners work. It stores the 'translated' block function that
 * will be sent to JS for add/remove
 */
@interface PPManticoreEventHolder : NSObject

@property (nonatomic,copy) id block;

@end


/**
 * The native interface represents the main object exposed to the Javascript
 * layer in order to communicate with the native layer for hardware, ui, etc.
 */
@interface PPManticoreNativeInterface : NSObject <JSExport>

@property (nonatomic,strong,readonly) JSValue *manticoreObject;

- (instancetype)initWithEngine:(PPManticoreEngine *)engine;

-(void)log:(NSString*)level component:(NSString*)component message:(NSString*)message;
-(JSValue*)http:(JSValue*)options callback:(JSValue*)callback;
-(JSValue*)setTimeout:(void (^)())function after:(NSInteger)milliseconds;

@end
