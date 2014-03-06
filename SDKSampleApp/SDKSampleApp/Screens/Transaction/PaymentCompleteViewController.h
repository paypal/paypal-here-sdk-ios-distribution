//
//  PaymentCompleteViewController.h
//  SDKSampleApp
//
//  Created by Chandrashekar,Sathyanarayan on 3/5/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>

@interface PaymentCompleteViewController : UIViewController

@property (strong, nonatomic) PPHTransactionRecord * transactionRecord;

-(IBAction)onEmailPressed:(id)sender;
-(IBAction)onTextPressed:(id)sender;
-(IBAction)onNoThanksPressed:(id)sender;

@end
