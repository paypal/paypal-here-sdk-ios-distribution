//
//  PaymentCompleteViewController.h
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface PaymentCompleteViewController : UIViewController

- (instancetype)initWithTransactionResponse:(PPHTransactionResponse *)response;

@end
