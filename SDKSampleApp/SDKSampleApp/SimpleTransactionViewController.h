//
//  SimpleTransactionViewController.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SimpleTransactionViewController : UIViewController <UITextFieldDelegate>
@property (nonatomic, retain) IBOutlet UILabel *description;
@property (nonatomic, retain) IBOutlet UIButton *purchase;
@property (nonatomic, retain) IBOutlet UITextField *price;
@end
