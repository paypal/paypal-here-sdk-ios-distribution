//
//  ReceiptInfoViewController.h
//  SDKSampleApp
//
//  Created by Chandrashekar,Sathyanarayan on 3/5/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPHTransactionRecord;
@interface ReceiptInfoViewController : UIViewController
<
UIAlertViewDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *infoLabel;
@property (weak, nonatomic) IBOutlet UITextField *infoTextField;
@property (strong, nonatomic) PPHTransactionRecord * transactionRecord;

@property (nonatomic) BOOL isEmail;

-(IBAction)onSendPressed:(id)sender;

@end
