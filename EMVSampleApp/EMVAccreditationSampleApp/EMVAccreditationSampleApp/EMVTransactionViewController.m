//
//  EMVTransactionViewController.m
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 Curam, Abhay. All rights reserved.
//

#import "EMVTransactionViewController.h"
#import <PayPalHereSDK/PPHTransactionManager.h>

@interface EMVTransactionViewController ()
@property(strong, nonatomic) PPHCardReaderWatcher *cardReaderWatcher;
@end

@implementation EMVTransactionViewController

#pragma mark
#pragma mark - View Controller Setup

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        self.cardReaderWatcher = [[PPHCardReaderWatcher alloc] initWithSimpleDelegate:self];
        self.emvMetaData = nil;
        self.currentDeviceInfo = nil;
    }
    
    return self;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.transactionAmountField.delegate = self;
}


- (void)viewWillAppear:(BOOL)animated {
    
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    
    if (tm.hasActiveTransaction) {
        [tm cancelPayment];
    }
    
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
    self.emvConnectionStatus.text = @"EMV device connected, you can begin transacting";
    self.emvMetaData = metadata;
}

-(void)didDetectReaderDevice:(PPHCardReaderBasicInformation *)reader
{
    self.emvConnectionStatus.textColor = [UIColor greenColor];
    self.emvConnectionStatus.text = @"We have detected an EMV device, please wait for it to connect";
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
    
    if (self.emvMetaData && self.transactionAmountField.text) {

        PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
        NSDecimalNumber *decimalAmount = [[NSDecimalNumber alloc]
                                          initWithString:self.transactionAmountField.text];
        
        PPHAmount *amount = [PPHAmount amountWithDecimal:decimalAmount inCurrency:@"US"];
        [tm beginPaymentWithAmount:amount andName:@"accreditationTestTransactionItem"];
        
        //Calling processPaymentWithSDKUI here...
        
        /*[tm processPaymentUsingSDKUI_WithPaymentType:ePPHPaymentMethodChipCard withTransactionController:nil completionHandler:^(PPHTransactionResponse *record) {
         
        }];*/
        
    }
    
}

- (IBAction)salesHistoryButtonPressed:(id)sender {
    
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
