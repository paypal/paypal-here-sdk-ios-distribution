//
//  RefundViewController.m
//  SDKSampleApp
//
//  Created by Chandrashekar,Sathyanarayan on 3/13/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionManager.h>
#import <PayPalHereSDK/PPHInvoice.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>
#import "RefundViewController.h"
#import "STAppDelegate.h"

@interface RefundViewController ()

@property (strong, nonatomic) NSMutableArray *transactionRecords;

@end

@implementation RefundViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.transactionRecords = appDelegate.transactionRecords;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.transactionRecords count];
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"RefundCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    PPHTransactionRecord *tr = [self.transactionRecords objectAtIndex:indexPath.row];
    cell.textLabel.text = tr.payPalInvoiceId;
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PPHTransactionRecord *record = [self.transactionRecords objectAtIndex:indexPath.row];
    if(record != nil) {
        [self performRefund:record];
    } else {
        // Show an error message.
    }
}

// Call the refund API within the SDK to perform the refund.
-(void) performRefund: (PPHTransactionRecord *) trxnRecord
{
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    [tm beginRefund:trxnRecord forAmount:trxnRecord.invoice.totalAmount completionHandler:^(PPHPaymentResponse * response) {
        if(response.error) {
            [self showAlertWithTitle:@"Refund Error" andMessage:response.error.description];
        } else {
            [self showAlertWithTitle:@"Refund Successful" andMessage:@"Your transaction amount was successfully refunded."];
        }
        // Remove this transaction record from the table view.
        [self removeRefundedRecordFromTableView:trxnRecord];
    }];
}

-(void) removeRefundedRecordFromTableView: (PPHTransactionRecord *) trxnRecord
{
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.transactionRecords removeObject: trxnRecord];
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

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
