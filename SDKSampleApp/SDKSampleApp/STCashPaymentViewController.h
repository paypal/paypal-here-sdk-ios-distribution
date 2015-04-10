//
//  STCashPaymentViewController.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PayPalHereSDK.h"

@interface STCashPaymentViewController : UIViewController
@property(nonatomic, weak) IBOutlet UIActivityIndicatorView *activity;

- (id)initWithAmount: (NSString *)amount nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
@end
