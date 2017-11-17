//
//  ViewController.m
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "ViewController.h"
#import <PayPalRetailSDK/PayPalRetailSDK.h>

@interface ViewController ()
@property (nonatomic,assign) BOOL didInit;
@property (nonatomic,strong) PPRetailTransactionContext *transactionContext;
@property (nonatomic,strong) PPRetailEmvDevice *emvDevice;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (!self.didInit) {
        self.didInit = YES;
        self.chargeButton.enabled = NO;
        self.enterPanButton.enabled = NO;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"testToken" ofType:@"txt"];
        NSString *token = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        self.statusLabel.stringValue = @"Initializing Merchant in SDK";
        [PayPalRetailSDK initializeMerchant:token completionHandler:^(PPRetailError *error, PPRetailMerchant *merchant) {
            if (error) {
                self.statusLabel.stringValue = [NSString stringWithFormat:@"Init failed: %@", error];
            } else {
                self.statusLabel.stringValue = [NSString stringWithFormat:@"Ready for %@", merchant.emailAddress];
                self.chargeButton.enabled = YES;
            }
        }];
        [PayPalRetailSDK addDeviceDiscoveredListener:^(PPRetailPaymentDevice *device) {
            if ([device isKindOfClass:[PPRetailEmvDevice class]]) {
                self.enterPanButton.enabled = YES;
                self.emvDevice = (PPRetailEmvDevice*)device;
            }
        }];
    }
}

- (IBAction)chargeButtonPressed:(id)sender {
    PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initWithCurrencyCode:nil];
    [invoice addItem:@"Amount" quantity:PAYPALNUM(@"1") unitPrice:PAYPALNUM(self.amountField.stringValue) itemId:@"Id" detailId:nil];
    self.statusLabel.stringValue = @"Creating transaction.";
    self.transactionContext = [PayPalRetailSDK createTransaction:invoice];
    [self.transactionContext begin: YES];
    self.statusLabel.stringValue = @"Ready for payment.";
}

- (IBAction)enterPANPressed:(id)sender {
    PPRetailSecureEntryOptions *options = [PPRetailSecureEntryOptions new];
    options.expiration = YES;
    options.cvv = YES;
    [self.emvDevice promptForSecureAccountNumber:options callback:^(PPRetailError *error, PPRetailManuallyEnteredCard *card) {
        if (card) {
            PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initWithCurrencyCode:nil];
            [invoice addItem:@"Amount" quantity:PAYPALNUM(@"1") unitPrice:PAYPALNUM(self.amountField.stringValue) itemId:@"Id" detailId:nil];
            self.statusLabel.stringValue = @"Creating transaction.";
            self.transactionContext = [PayPalRetailSDK createTransaction:invoice];
            [self.transactionContext continueWithCard:card];
        }
    }];
}
@end
