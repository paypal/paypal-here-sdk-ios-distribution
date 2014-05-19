//
//  AuthorizedInvoiceInspectorViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/14/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "AuthorizedInvoiceInspectorViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>

@interface AuthorizedInvoiceInspectorViewController ()
@property (strong, nonatomic) PPHTransactionRecord * transactionRecord;
@end

@implementation AuthorizedInvoiceInspectorViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil transactionRecord:(PPHTransactionRecord *)record
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.transactionRecord = record;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.title = @"Authorized Invoice";
    
    self.enteredNewAmount.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onVoid:(id)sender {
    
}

- (IBAction)onCapture:(id)sender {
    
}

- (IBAction)onCaptureNewAmount:(id)sender {
    
}

@end
