//
//  AppDelegate.h
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PaymentViewController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) PaymentViewController *transactionViewController;

@end

