//
//  EMVTransactionViewController.h
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 Curam, Abhay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionManager.h>

@interface EMVTransactionViewController : UIViewController <
PPHCardReaderDelegate,
UITextFieldDelegate
>

@property(weak, nonatomic) IBOutlet UILabel *emvConnectionStatus;
@property(weak, nonatomic) IBOutlet UILabel *emvDeviceInformation;
@property(weak, nonatomic) IBOutlet UITextField *transactionAmountField;
@property(weak, nonatomic) IBOutlet UIButton *chargeButton;
@property(weak, nonatomic) IBOutlet UIButton *salesHistoryButton;

@property(strong, nonatomic) PPHCardReaderBasicInformation *currentDeviceInfo;
@property(strong, nonatomic) PPHCardReaderMetadata *emvMetaData;

-(IBAction)transactionAmountFieldReturned:(id)sender;
-(IBAction)chargeButtonPressed:(id)sender;
-(IBAction)salesHistoryButtonPressed:(id)sender;

@end
