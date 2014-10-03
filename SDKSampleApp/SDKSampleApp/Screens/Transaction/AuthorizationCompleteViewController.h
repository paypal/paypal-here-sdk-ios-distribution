//
//  AuthorizationCompleteViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/13/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPHTransactionResponse;

@interface AuthorizationCompleteViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *authResultLabel;
@property (weak, nonatomic) IBOutlet UILabel *invoiceAmountLabel;
@property (weak, nonatomic) IBOutlet UILabel *invoiceNumberLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;



-(IBAction)onDone:(id)sender;

-(IBAction)onCaptureNow:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
           forAuthResponse:(PPHTransactionResponse *)authorizationResponse;

@end
