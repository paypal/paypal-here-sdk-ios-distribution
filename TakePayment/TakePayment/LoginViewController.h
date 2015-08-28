//
//  LoginViewController.h
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#define kSavedToken @"savedToken"

@interface LoginViewController : UIViewController

- (void)initializeSDKMerchantWithToken:(NSString *)token;

@end
