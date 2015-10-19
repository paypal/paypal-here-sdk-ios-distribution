//
//  AppDelegate.h
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LoginViewController.h"
#import "PaymentViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

- (LoginViewController *)loginVC;
- (PaymentViewController *)paymentVC;

@end

