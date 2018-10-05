//
//  PPRetailTransactionBeginOptions+SET_DEFAULT.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "PPRetailTransactionBeginOptions+SET_DEFAULT.h"

@implementation PPRetailTransactionBeginOptions (SET_DEFAULT)

+(PPRetailTransactionBeginOptions*) defaultOptions {
    PPRetailTransactionBeginOptions *options = [[PPRetailTransactionBeginOptions alloc] init];
    options.showPromptInCardReader = YES;
    options.showPromptInApp = YES;
    options.preferredFormFactors =[NSArray new];
    options.tippingOnReaderEnabled = NO;
    options.amountBasedTipping = NO;
    options.isAuthCapture = NO;
    options.quickChipEnabled = NO;
    options.tag = @"";
    return options;
}

@end
