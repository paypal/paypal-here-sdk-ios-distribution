//
//  EmvAutomationBridge.h
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/2/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPAutomationBridge.h"

@interface EmvAutomationBridge : NSObject<
    PPAutomationBridgeDelegate
>

-(NSDictionary*)login:(NSDictionary*) args;

@end
