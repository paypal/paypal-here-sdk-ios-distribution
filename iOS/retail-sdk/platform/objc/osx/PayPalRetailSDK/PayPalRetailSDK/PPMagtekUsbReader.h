//
//  PPMagtekUsbReader.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/17/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <IOKit/hid/IOHIDBase.h>
#import "PPRetailObject.h"

@interface PPMagtekUsbReader : PPRetailObject
-(instancetype)initWithDevice:(IOHIDDeviceRef)device andSerial:(NSString *)serial;
@property (atomic,assign) BOOL isAvailable;
@end
