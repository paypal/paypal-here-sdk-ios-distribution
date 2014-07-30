//
//  STServices.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/20/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#define IS_IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

typedef enum {
    kSASimple,
    kSAFS,
    kSACCC,
    kSAError
} kSAFlow;

@interface STServices : NSObject
+(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message;

@end
