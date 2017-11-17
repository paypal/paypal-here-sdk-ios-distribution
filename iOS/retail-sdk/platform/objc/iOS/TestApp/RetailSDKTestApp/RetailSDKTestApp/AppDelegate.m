//
//  AppDelegate.m
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "AppDelegate.h"
#import "EmvAutomationBridge.h"
#import <PayPalRetailSDK/PayPalRetailSDK.h>

#define VIRTUAL_DEVICE_SERVER   @"wss://10.224.146.158:8080"

@interface AppDelegate ()
@property (nonatomic, strong) EmvAutomationBridge *automationBridge;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.automationBridge = [EmvAutomationBridge new];
    [[PPAutomationBridge bridge] startAutomationBridgeWithPrefix:@"EMVAutomation" onPort:4200 WithDelegate:self.automationBridge];
    
    return YES;
}

@end
