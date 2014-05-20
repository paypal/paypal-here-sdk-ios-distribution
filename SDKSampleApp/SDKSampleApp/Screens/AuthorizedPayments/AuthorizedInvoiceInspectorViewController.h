//
//  AuthorizedInvoiceInspectorViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/14/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPHTransactionRecord;

@interface AuthorizedInvoiceInspectorViewController : UIViewController
<
UITextFieldDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *actionLabel;
@property (weak, nonatomic) IBOutlet UILabel *originalAmount;
@property (weak, nonatomic) IBOutlet UILabel *invoiceId;
@property (weak, nonatomic) IBOutlet UITextField *enteredNewAmount;
@property (weak, nonatomic) IBOutlet UIButton *voidButton;
@property (weak, nonatomic) IBOutlet UIButton *captureOrigAmountButton;
@property (weak, nonatomic) IBOutlet UIButton *captureNewAmountButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;


- (IBAction)onVoid:(id)sender;
- (IBAction)onCapture:(id)sender;
- (IBAction)onCaptureNewAmount:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil transactionRecord:(PPHTransactionRecord *)record;
@end
