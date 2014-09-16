//
//  EMVTransactionViewController.m
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 Curam, Abhay. All rights reserved.
//

#import "EMVTransactionViewController.h"
#import "EMVSalesHistoryViewController.h"
#import <PayPalHereSDK/PPHTransactionManager.h>
#import "AppDelegate.h"

@interface EMVTransactionViewController ()
@property (strong, nonatomic) PPHCardReaderWatcher *cardReaderWatcher;
@end

@implementation EMVTransactionViewController

#pragma mark
#pragma mark - View Controller Setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.cardReaderWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
        self.emvMetaData = nil;
        self.currentDeviceInfo = nil;
    }
    
    return self;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.transactionAmountField.delegate = self;
    self.chargeButton.layer.cornerRadius = 10;
    self.salesHistoryButton.layer.cornerRadius = 10;
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    if (tm.hasActiveTransaction) {
        [tm cancelPayment];
    }
    
    [[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark
#pragma mark - IBActions and delegate events

-(void)didRemoveReader:(PPHReaderType)readerType
{
	self.emvConnectionStatus.textColor = [UIColor redColor];
    self.emvConnectionStatus.text = @"No EMV device paired, please connect one before transacting";
    self.currentDeviceInfo = nil;
    self.emvMetaData = nil;
}

-(void)didReceiveCardReaderMetadata:(PPHCardReaderMetadata *)metadata
{
    self.emvConnectionStatus.textColor = [UIColor blueColor];
    self.emvConnectionStatus.text = @"EMV device connected";
    self.emvMetaData = metadata;
}

-(void)didDetectReaderDevice:(PPHCardReaderBasicInformation *)reader
{
    self.emvConnectionStatus.textColor = [UIColor blueColor];
    self.emvConnectionStatus.text = @"EMV device connected";
    self.currentDeviceInfo = reader;
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    
    if (self.emvMetaData) {
        return YES;
    }
    
    else {
        return NO;
    }
    
}

- (IBAction)transactionAmountFieldReturned:(id)sender {
    [sender resignFirstResponder];
}

- (IBAction)chargeButtonPressed:(id)sender {
    
    [_transactionAmountField resignFirstResponder];
    
    if (self.emvMetaData) {
        
        if (self.transactionAmountField.text) {
            
            PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
            NSDecimalNumber *decimalAmount = [[NSDecimalNumber alloc]
                                          initWithString:self.transactionAmountField.text];
            
            if(NSOrderedSame == [[NSDecimalNumber notANumber] compare: decimalAmount]) {
                //They have not entered a valid number.  Bail.
                NSLog(@"No valid number entered.  Bailing");
                return;
            }
            
            PPHAmount *amount = [PPHAmount amountWithDecimal:decimalAmount inCurrency:@"GBP"];
            [tm beginPaymentWithAmount:amount andName:@"accreditationTestTransactionItem"];
        
            PPHAvailablePaymentTypes paymentPermissions = [[PayPalHereSDK activeMerchant] payPalAccount].availablePaymentTypes;
        
            if (ePPHAvailablePaymentTypeChip & paymentPermissions) {
            
            //Code is not yet implemented
                [tm processPaymentUsingSDKUI_WithPaymentType:ePPHPaymentMethodChipCard
                                   withTransactionController:nil
                                          withViewController:self
                                           completionHandler:^(PPHTransactionResponse *record) {
                
                                               if(record) {
                                                   if (!record.error && record.record.transactionId) {
                                                       [self saveTransactionRecordForRefund:record.record];
                                                   }
                                                   else if(record.error.code == kPPHLocalErrorBadConfigurationPaymentAmountOutOfBounds)  {
                                                       // This happens when the user is attempting to charge an amount that's outside
                                                       // of the allowed bounds for this merchant.  Different merchants have different
                                                       // min and max amounts they can charge.
                                                       //
                                                       // Your app can check these bounds before kicking off the payment (and eventually
                                                       // getting this error).  To do that, please check the PPHPaymentLimits object found
                                                       // via [[[PayPalHereSDK activeMerchant] payPalAccount] paymentLimits].
                                                       
                                                       NSLog(@"The app attempted to charge an out of bounds amount.");
                                                       NSLog(@"Dev Message: %@", [record.error.userInfo objectForKey:@"DevMessage"]);
                                                       
                                                       [self showAlertWithTitle:@"Amount is out of bounds" andMessage:nil];
                                                   }
                                               }

                                               
                }];
            
            } else {
                [self showAlertWithTitle:@"Payment Failure" andMessage:@"Unfortunately you can not take EMV payments, please call PayPal and get the appropriate permissions."];
            }
        
        } else {
            [self showAlertWithTitle:@"Please enter a transaction amount." andMessage:nil];
        }
    
    } else {
        [self showAlertWithTitle:@"No EMV Data" andMessage:@"Please make sure your EMV device is paired"];
    }
    
}

-(void) saveTransactionRecordForRefund:(PPHTransactionRecord *)record {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Add the record into an array so that we can issue a refund later.
    [appDelegate.transactionRecords addObject:record];
}

-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:nil
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    
    [alertView show];
}

- (IBAction)salesHistoryButtonPressed:(id)sender {
    EMVSalesHistoryViewController *vc = [[EMVSalesHistoryViewController alloc] init];
    vc.title = @"Sales History";
    [self.navigationController pushViewController:vc animated:YES];
}

@end
