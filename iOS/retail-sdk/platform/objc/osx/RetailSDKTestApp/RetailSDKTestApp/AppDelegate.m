//
//  AppDelegate.m
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "AppDelegate.h"
#import <PayPalRetailSDK/PayPalRetailSDK.h>

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [PayPalRetailSDK initializeSDK];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

@end
