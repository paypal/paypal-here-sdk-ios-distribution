//
//  SimpleFSPaymentDelegate.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/20/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TransactionViewController.h"
#import "STServices.h"

@interface SimpleFSPaymentDelegate : NSObject <PaymentProtocol>
-(kSAFlow) purchase:(PPHInvoice *)invoice;
@end
