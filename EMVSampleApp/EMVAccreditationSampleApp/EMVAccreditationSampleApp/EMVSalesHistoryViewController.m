//
//  EMVSalesHistoryViewController.m
//  EMVAccreditationSampleApp
//
//  Created by Chandrashekar, Sathyanarayan on 8/18/14.
//  Copyright (c) 2014 Chandrashekar, Sathyanarayan. All rights reserved.
//

#import "EMVSalesHistoryViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>
#import "AppDelegate.h"

#define kRefundOptionsDialog 1
#define kRefundAmountDialog 2
#define kRefundAmountInvalidDialog 3
#define kRefundRecordAlreadyRefundedDialog 4

#define kRecordAlreadyRefundedServerError @"The request was refused.This transaction has already been fully refunded"

typedef NS_ENUM(NSInteger, InvalidRefundAmountReason) {
    InvalidRefundAmountReasonOutsideRange,
    InvalidRefundAmountReasonNegativeNumber,
    InvalidRefundAmountReasonZero,
    InvalidRefundAmountReasonNAN
};


@interface EMVSalesHistoryViewController () <
PPHTransactionControllerDelegate,
UIAlertViewDelegate,
UIActionSheetDelegate
>

@property (nonatomic, strong) PPHTransactionRecord *record;
@property (nonatomic, strong) PPHAmount *collectedRefundForRecord;
@property (nonatomic, copy) NSString *targetCurrency;
@property (nonatomic, strong) PPHAmount *amountToRefund;
@property (nonatomic, assign) NSUInteger tableIndex;
@property (nonatomic, assign) BOOL isFullRefund;
@end

@implementation EMVSalesHistoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Sales History";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseIdentifier"];
}

#pragma mark -
#pragma mark UITableViewDelegate and UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"reuseIdentifier"];
    
    PPHTransactionRecord *record = [appDelegate.transactionRecords objectAtIndex:indexPath.row];
    PPHAmount *partialRefund = [appDelegate.refunds objectAtIndex:indexPath.row];
    
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    [cell.textLabel setFont:[UIFont systemFontOfSize:13]];
    cell.textLabel.textColor = [UIColor blueColor];
    cell.textLabel.text = [NSString stringWithFormat:@"Txn #%d | %@", indexPath.row + 1, record.invoice.totalAmount.stringValue];
    
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.textColor = [UIColor redColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"Refunded Amount: +%@", partialRefund.stringValue];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    return [appDelegate.transactionRecords count];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSLog(@"%@", cell.textLabel.text);
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    // Lets set the record and the selected table index for now.
    // We would need to set the amount a bit later, based on the user's selection of either a full or a partial refund.
    self.record = [appDelegate.transactionRecords objectAtIndex:indexPath.row];
    self.targetCurrency = self.record.invoice.totalAmount.currencyCode;
    self.tableIndex = indexPath.row;
    self.collectedRefundForRecord = [appDelegate.refunds objectAtIndex:indexPath.row];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showRefundOptionsAlertDialog];
}

- (NSDecimalNumber *)getDecimalAmountFromString:(NSString *)amountStr {
    NSDecimalNumber *decimalAmount = [[NSDecimalNumber alloc]
                                      initWithString:amountStr];
    
    if(NSOrderedSame == [[NSDecimalNumber notANumber] compare: decimalAmount]) {
        return nil;
    }
    return decimalAmount;
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == kRefundRecordAlreadyRefundedDialog) {
        self.isFullRefund = YES;
        [self updateSalesHistoryTable:self.tableIndex];
    } else if (alertView.tag == kRefundOptionsDialog) {
        if(buttonIndex == alertView.cancelButtonIndex) {
        } else if (buttonIndex == 1) {
            [self showEnterAmountTextDialog];
        } else if (buttonIndex == 2){
            self.isFullRefund = YES;
            self.amountToRefund = self.record.invoice.totalAmount;
            [self performRefundWithRecord];
        }
        
    } else if (alertView.tag == kRefundAmountDialog) {
        if(buttonIndex == alertView.cancelButtonIndex) {
            // Clear the alert view
        } else if (buttonIndex == 0) {
            UITextField * amountTextField = [alertView textFieldAtIndex:0];
            if ([self getDecimalAmountFromString:amountTextField.text]) {
                self.amountToRefund = [PPHAmount amountWithString:amountTextField.text inCurrency:self.targetCurrency];
                NSInteger currentRefundAmount = self.amountToRefund.amountInCents;
                NSInteger collectedRefundAmount = self.collectedRefundForRecord.amountInCents;
                NSInteger fullRefundContribution = currentRefundAmount + collectedRefundAmount;
                NSInteger totalTransactionAmount = self.record.invoice.totalAmount.amountInCents;
                
                //Refund within acceptable range: [0, totalTransactionAmount)
                if (fullRefundContribution <= totalTransactionAmount && fullRefundContribution > 0) {
                    
                    if (fullRefundContribution == totalTransactionAmount) {
                        self.isFullRefund = YES;
                    } else {
                        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                        NSDecimalNumber *newRefund = [self.amountToRefund.amount decimalNumberByAdding:self.collectedRefundForRecord.amount];
                        PPHAmount *newRefundAmount = [PPHAmount amountWithDecimal:newRefund inCurrency:self.targetCurrency];
                        [appDelegate.refunds replaceObjectAtIndex:self.tableIndex withObject:newRefundAmount];
                    }
                    
                    [self performRefundWithRecord];
                
                //Refunds outside acceptable range
                } else {
                    
                    if (currentRefundAmount < 0) {
                        [self showInvalidRefundAmountDialogForReason:InvalidRefundAmountReasonNegativeNumber];
                    }
                    else if (currentRefundAmount == 0) {
                        [self showInvalidRefundAmountDialogForReason:InvalidRefundAmountReasonZero];
                    } else {
                        [self showInvalidRefundAmountDialogForReason:InvalidRefundAmountReasonOutsideRange];
                    }
                
                }
                
            } else {
                [self showInvalidRefundAmountDialogForReason:InvalidRefundAmountReasonNAN];
            }
        }
    }
}

#pragma mark -
#pragma mark PPHTransactionControllerDelegate

- (PPHTransactionControlActionType)onPreAuthorizeForInvoice:(PPHInvoice *)inv withPreAuthJSON:(NSMutableDictionary*)preAuthJSON {
    return ePPHTransactionType_Continue;
}

- (void)onPostAuthorize:(BOOL)didFail {

}

- (void)onUserPaymentMethodSelected:(PPHPaymentMethod) paymentMethod {
    
}

- (void)onUserRefundMethodSelected:(PPHPaymentMethod) paymentMethod {
    
}

- (UIViewController *)getCurrentViewController {
    return self;
}

#pragma mark -
#pragma mark Helpers

- (void)showInvalidRefundAmountDialogForReason:(InvalidRefundAmountReason)reason {
    NSString *failureMessage = nil;
    switch (reason) {
        case InvalidRefundAmountReasonOutsideRange:
            failureMessage = @"You are attempting to refund for an amount greater than the original payment";
            break;
        case InvalidRefundAmountReasonNegativeNumber:
            failureMessage = @"You can not refund for a negative amount.";
            break;
        case InvalidRefundAmountReasonNAN:
            failureMessage = @"Please make sure you enter a valid numerical amount";
            break;
        case InvalidRefundAmountReasonZero:
            failureMessage = @"You can not refund for zero dollars, please enter an amount greater than zero";
            break;
        default:
            break;
    }
    
    UIAlertView *failureRefundAmountView = [[UIAlertView alloc] initWithTitle:@"Invalid refund amount" message:failureMessage delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    failureRefundAmountView.tag = kRefundAmountInvalidDialog;
    [failureRefundAmountView show];
}

- (void)showRecordAlreadyRefundedAlert {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Transaction already refunded" message:@"Sorry our stages are really slow, but this transaction has already been completely refunded." delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
    alert.tag = kRefundRecordAlreadyRefundedDialog;
    [alert show];
}

- (void)showRefundOptionsAlertDialog {
    UIAlertView *refundOptionAlertDialog = [[UIAlertView alloc] initWithTitle:@"Refund" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Refund partial amount", nil];
    AppDelegate *appDelegate = ((AppDelegate *)[[UIApplication sharedApplication] delegate]);
    PPHAmount *refundAmountForTransaction = [appDelegate.refunds objectAtIndex:self.tableIndex];
    if ([refundAmountForTransaction.amount compare:[NSDecimalNumber zero]] == NSOrderedSame) {
        [refundOptionAlertDialog addButtonWithTitle:@"Refund full amount"];
    }
    
    refundOptionAlertDialog.tag = kRefundOptionsDialog;
    [refundOptionAlertDialog show];
}

- (void)showEnterAmountTextDialog {
    UIAlertView *partialAmountDialog = [[UIAlertView alloc] initWithTitle:@"Enter refund amount" message:nil delegate:self cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
    partialAmountDialog.alertViewStyle = UIAlertViewStylePlainTextInput;
    partialAmountDialog.tag = kRefundAmountDialog;
    [partialAmountDialog show];
}

- (void)performRefundWithRecord {
    // call SDK UI for refund
    [[PayPalHereSDK sharedTransactionManager] beginRefundUsingSDKUIWithInvoice:self.record.invoice transactionController:self];
    [[PayPalHereSDK sharedTransactionManager] processRefundUsingSDKUIWithAmount:self.amountToRefund completionHandler:^(PPHTransactionResponse *response) {
        NSLog(@"Refund completed.");
        
        if(response) {
            if(response.record && !response.error) {
                [self updateSalesHistoryTable:self.tableIndex];
            } else {
                if ([response.error.apiShortMessage isEqualToString:kRecordAlreadyRefundedServerError]) {
                    [self showRecordAlreadyRefundedAlert];
                }
            }
        }
    }];
}

- (void)updateSalesHistoryTable:(NSUInteger)objectToModify {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (self.isFullRefund) {
        [appDelegate.transactionRecords removeObjectAtIndex:objectToModify];
        [appDelegate.refunds removeObjectAtIndex:objectToModify];
    }
    [self.tableView reloadData];
}

@end
