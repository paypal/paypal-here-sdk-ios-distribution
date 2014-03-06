//
//  ReceiptInfoViewController.m
//  SDKSampleApp
//
//  Created by Chandrashekar,Sathyanarayan on 3/5/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "ReceiptInfoViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionManager.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>
#import <PayPalHereSDK/PPHReceiptDestination.h>

@interface ReceiptInfoViewController ()

@property BOOL doneWithReceiptScreen;

@end

@implementation ReceiptInfoViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.doneWithReceiptScreen = NO;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

-(void) viewWillAppear:(BOOL)animated {
    if(_isEmail) {
        _infoLabel.text = @"Please provide an email address";
    } else {
        _infoLabel.text = @"Please provide a phone number";
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onSendPressed:(id)sender
{

    // Make sure the user has entered some amount:
    NSString *infoString = self.infoTextField.text;
    if ([infoString length] == 0) {
        [self showAlertWithTitle:@"Input Error" andMessage:_infoLabel.text];
        return;
    }
    
    _doneWithReceiptScreen = YES;
    
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHReceiptDestination * destination = [[PPHReceiptDestination alloc] init];
    destination.destinationAddress = infoString;
    destination.isEmail = _isEmail;
    [tm sendReceipt:_transactionRecord toRecipient: destination completionHandler:^(PPHError *error) {
        if(error == nil) {
            [self showAlertWithTitle:@"Receipt Sent" andMessage:@"Please wait for a few minutes to receive the receipt on your device."];
            
        } else {
            [self showAlertWithTitle:@"Error while sending receipt." andMessage:error.description];
        }
    }];
}

-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:self
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(_doneWithReceiptScreen)
        [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
