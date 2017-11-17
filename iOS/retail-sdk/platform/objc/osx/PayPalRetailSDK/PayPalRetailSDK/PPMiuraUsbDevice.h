//
//  PPMiuraUsbDevice.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/5/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPRetailObject.h"

@interface PPMiuraUsbDevice : PPRetailObject
-(instancetype)initWithPort:(NSString*)serialPort;
@end
