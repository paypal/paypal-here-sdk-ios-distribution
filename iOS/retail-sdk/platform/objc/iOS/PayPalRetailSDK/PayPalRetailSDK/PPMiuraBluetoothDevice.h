//
//  PPMiuraBluetoothDevice.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ExternalAccessory/ExternalAccessory.h>
#import "PayPalRetailSDK+Private.h"

@protocol PPMiuraBluetoothDeviceDelegate

- (void)deviceRemovalRequestedForSerialNumber:(NSString *)serial;

@end

@interface PPMiuraBluetoothDevice : PPRetailObject

@property (nonatomic, strong) EAAccessory *nativeReader;

- (instancetype)initWithAccessory:(EAAccessory*)accessory delegate:(id<PPMiuraBluetoothDeviceDelegate>)delegate;
- (BOOL)connectToNewAccessory:(EAAccessory*)accessory;

@end
