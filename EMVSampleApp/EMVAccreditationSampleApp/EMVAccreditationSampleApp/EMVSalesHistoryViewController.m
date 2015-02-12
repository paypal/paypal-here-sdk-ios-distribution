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


@interface EMVSalesHistoryViewController () <
PPHTransactionControllerDelegate,
UIAlertViewDelegate,
UIActionSheetDelegate
>

@property (nonatomic, strong) PPHTransactionRecord *record;
@property (nonatomic, strong) PPHAmount *amount;
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    PPHTransactionRecord *record = [appDelegate.transactionRecords objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"%@ : %@", record.payPalInvoiceId ? record.payPalInvoiceId : record.invoice.paypalInvoiceId, [record.invoice.totalAmount stringValue]];
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
    self.tableIndex = indexPath.row;
    
    [self showRefundOptionsAlertDialog];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.tag == kRefundOptionsDialog) {
        if(buttonIndex == alertView.cancelButtonIndex) {
            // Clear the alert view
        } else if (buttonIndex == 1) {
            // Full amount refund.
            self.isFullRefund = YES;
            self.amount = self.record.invoice.totalAmount;
            [self performRefundWithRecord];
            
        } else if (buttonIndex == 2){
            // Partial amount refund.
            [self showEnterAmountTextDialog];
        }
        
    } else if (alertView.tag == kRefundAmountDialog) {
        if(buttonIndex == alertView.cancelButtonIndex) {
            // Clear the alert view
        } else if (buttonIndex == 0) {
            UITextField * amountTextField = [alertView textFieldAtIndex:0];
            self.amount = [PPHAmount amountWithString:amountTextField.text inCurrency:@"GBP"];
            [self performRefundWithRecord];
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

- (void)onReadyForPayment {

}

- (void)onReadyForRefund {

}

- (UIViewController *)getCurrentViewController {
    return self;
}

#pragma mark -
#pragma mark Helpers

- (void)showRefundOptionsAlertDialog {
    UIAlertView *refundOptionAlertDialog = [[UIAlertView alloc] initWithTitle:@"Refund" message:nil delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Refund full amount", @"Refund partial amount", nil];
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
    [[PayPalHereSDK sharedTransactionManager] beginRefundWithInvoice:self.record.invoice transactionController:self];
    [[PayPalHereSDK sharedTransactionManager] processRefundWithAmount:self.amount completionHandler:^(PPHTransactionResponse *response) {
        NSLog(@"Refund completed.");
        
        if(response) {
            if(self.isFullRefund && response.record && !response.error) {
                [self updateSalesHistoryTable:self.tableIndex];
            }
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }];
}

- (void)updateSalesHistoryTable:(NSUInteger)objectToRemove {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.transactionRecords removeObjectAtIndex:objectToRemove];
    [self.tableView reloadData];
}

@end
