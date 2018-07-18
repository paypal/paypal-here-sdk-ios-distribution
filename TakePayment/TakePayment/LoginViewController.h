//
//  LoginViewController.h
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController

- (void)initializeSDKMerchantWithToken:(NSString *)token;
- (void)initializeSDKMerchantWithCredentials:(NSString *)access_token refreshUrl:(NSString *)refresh_url;
- (void)forgetTokens;

@end
