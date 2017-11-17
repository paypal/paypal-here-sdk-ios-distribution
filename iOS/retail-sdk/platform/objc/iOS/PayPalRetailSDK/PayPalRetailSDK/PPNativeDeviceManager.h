//
//  PPNativeDeviceManager.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/1/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>

@interface PPNativeDeviceManager : NSObject

- (void)startWatching;
- (void)stopWatching;

@end
