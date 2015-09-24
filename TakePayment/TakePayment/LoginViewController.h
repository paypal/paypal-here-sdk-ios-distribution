//
//  LoginViewController.h
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

- (void)initializeSDKMerchantWithToken:(NSString *)token;

@end
