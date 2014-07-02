//
//  PaymentCompleteViewController.h
//  SDKSampleApp
//
//  Created by Chandrashekar,Sathyanarayan on 3/5/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PPHTransactionResponse;
@interface PaymentCompleteViewController : UIViewController


@property (weak, nonatomic) IBOutlet UILabel *paymentStatus;
@property (weak, nonatomic) IBOutlet UILabel *paymentDetails;

-(IBAction)onEmailPressed:(id)sender;
-(IBAction)onTextPressed:(id)sender;
-(IBAction)onNoThanksPressed:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil
               bundle:(NSBundle *)nibBundleOrNil
          forResponse:(PPHTransactionResponse *)transactionResponse;

@end
