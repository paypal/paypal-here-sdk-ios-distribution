//
//  MiuraBluetoothDevice.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/4/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
#import "PPRetailObject.h"

@interface PPMiuraBluetoothDevice : PPRetailObject
-(instancetype)initWithDevice:(IOBluetoothDevice*)device;
@end
