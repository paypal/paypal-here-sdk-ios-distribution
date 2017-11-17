//
//  PaymentViewController.h
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/1/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PaymentViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *amountField;
@property (weak, nonatomic) IBOutlet UITextField *tipField;
@property (weak, nonatomic) IBOutlet UIButton *chargeButton;
@property (weak, nonatomic) IBOutlet UIButton *refundButton;
@property (weak, nonatomic) IBOutlet UIButton *authTxnsPageButton;

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *environment;

- (void)updateMerchantStatus;
- (IBAction)chargeButtonPressed:(id)sender;
- (IBAction)refundButtonPressed:(id)sender;
- (IBAction)authTxnsPageButtonPressed:(id)sender;

@end

