//
//  PaymentViewController.m
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/1/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PaymentViewController.h"
#import "AppDelegate.h"
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import "PPSCryptoUtils.h"

@interface PaymentViewController ()

@property (nonatomic,assign) BOOL didInit;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (weak, nonatomic) IBOutlet UILabel *activeLabel;

@property (nonatomic, strong) PPRetailTransactionContext *transactionContext;
@property (nonatomic, strong) PPRetailMerchant *merchant;
@property (nonatomic, strong) PPRetailTransactionRecord *previousTransaction;
@property (nonatomic, strong) PPRetailInvoice *previousInvoice;

@end

@implementation PaymentViewController

- (void)viewDidLoad {
    AppDelegate *app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    app.transactionViewController = self;
    
    [super viewDidLoad];
    if (!self.didInit) {
        self.didInit = YES;
        self.chargeButton.enabled = NO;
        self.authTxnsPageButton.enabled = NO;
        
        self.statusLabel.text = @"Initializing SDK";
        [PayPalRetailSDK initializeSDK];
        
        self.statusLabel.text = @"Initializing Merchant in SDK";
        [PayPalRetailSDK initializeMerchant:self.accessToken completionHandler:^(PPRetailError *error, PPRetailMerchant *merchant) {
            if (error) {
                self.statusLabel.text = [NSString stringWithFormat:@"Init failed: %@", error];
            } else {
                self.merchant = merchant;
                self.merchant.isCertificationMode = YES;
                self.statusLabel.text = [NSString stringWithFormat:@"Ready for %@", merchant.emailAddress];
                self.chargeButton.enabled = YES;
                self.authTxnsPageButton.enabled = YES;
            }
        }];
    }
}

- (IBAction)chargeButtonPressed:(id)sender {
    if (![self.amountField.text isEqualToString:@""]) {
        PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initWithCurrencyCode:self.merchant.currency];
        
        [invoice addItem:@"Amount" quantity:PAYPALNUM(@"1") unitPrice:PAYPALNUM(self.amountField.text) itemId:@"Id" detailId:nil];
        if (![self.tipField.text isEqualToString:@""]) {
            [invoice setGratuityAmount:PAYPALNUM(self.tipField.text)];
        }
        self.statusLabel.text = @"Creating transaction.";
        self.transactionContext = [PayPalRetailSDK createTransaction:invoice];
        [self.transactionContext begin];
        self.previousInvoice = invoice;
        self.statusLabel.text = @"Ready for payment.";
        
        __weak typeof(self) weakSelf = self;
        [self.transactionContext setCompletedHandler:^(PPRetailError *error, PPRetailTransactionRecord *record) {
            if (error) {
                weakSelf.statusLabel.text = [NSString stringWithFormat:@"Transaction failed: %@", error];
            } else {
                weakSelf.statusLabel.text = [NSString stringWithFormat:@"SUCCESS! %@", record.transactionNumber];
                weakSelf.previousTransaction = record;
            }
            [weakSelf.transactionContext dropHandlers];
            weakSelf.chargeButton.enabled = YES;
        }];
        
        [self.transactionContext setCardPresentedHandler:^(PPRetailCard *card) {
            weakSelf.statusLabel.text = @"Processing payment...";
            weakSelf.chargeButton.enabled = NO;
            [weakSelf.transactionContext continueWithCard:card];
        }];
    }
}

- (IBAction)refundButtonPressed:(id)sender {
    if (self.previousTransaction && self.previousInvoice) {
        self.transactionContext = [PayPalRetailSDK createTransaction:self.previousInvoice];
        [self.transactionContext beginRefund:YES amount:self.previousInvoice.total];
        
        __weak typeof(self) weakSelf = self;
        [self.transactionContext setCompletedHandler:^(PPRetailError *error, PPRetailTransactionRecord *record) {
            if (error) {
                weakSelf.statusLabel.text = [NSString stringWithFormat:@"Refund failed: %@", error];
            } else {
                weakSelf.statusLabel.text = [NSString stringWithFormat:@"Refunded! %@", record.transactionNumber];
                weakSelf.previousTransaction = nil;
                weakSelf.previousInvoice = nil;
                weakSelf.chargeButton.enabled = YES;
                weakSelf.refundButton.enabled = YES;
            }
            [weakSelf.transactionContext dropHandlers];
            weakSelf.chargeButton.enabled = YES;
        }];
    }
}

- (IBAction)authTxnsPageButtonPressed:(id)sender {
    [self performSegueWithIdentifier:@"showAuthorizedTransactions" sender:nil];
}

-(void)updateMerchantStatus {
    
}

-(void)setupAdditionalReceiptOptions {
    [self.transactionContext setAdditionalReceiptOptions:@[@"Print"] receiptHandler:^(int index, NSString *name, PPRetailTransactionRecord *record) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Printing..." message:@"Your custom option." delegate:nil cancelButtonTitle:@"Done" otherButtonTitles: nil];
        [alert show];
    }];
}

@end
