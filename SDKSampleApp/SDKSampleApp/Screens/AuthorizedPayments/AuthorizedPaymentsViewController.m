//
//  AuthorizedPaymentsViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/14/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "AuthorizedPaymentsViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionManager.h>
#import <PayPalHereSDK/PPHInvoice.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>

#import "AuthorizedInvoiceInspectorViewController.h"

@interface AuthorizedPaymentsViewController ()
@property (strong, nonatomic) NSArray *transactionRecords;
@property (assign, nonatomic) BOOL showingNoneAvailable;
@end

@implementation AuthorizedPaymentsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil transactionRecords:(NSArray *)records
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        _showingNoneAvailable = NO;
        _transactionRecords = records;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Authorized Invoices";

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
    int numTransactions = [self.transactionRecords count];
    if(numTransactions == 0) {
        numTransactions += 1;
        _showingNoneAvailable = YES;
    }
    
    return numTransactions;
}

-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AuthCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    if(_showingNoneAvailable) {
        cell.textLabel.text = @"There are no entries";
    } else {
        PPHTransactionRecord *tr = [self.transactionRecords objectAtIndex:indexPath.row];
        cell.textLabel.text = tr.payPalInvoiceId;
        cell.detailTextLabel.text = @"Authorized";
    }
    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(_showingNoneAvailable) {
        return;
    }
    
    PPHTransactionRecord *record = [self.transactionRecords objectAtIndex:indexPath.row];
    if(record != nil) {
        [self inspectRecord:record];
    } else {
        // Show an error message.
        NSLog(@"The selected record seems to be nil.");
    }
}

- (void) inspectRecord:(PPHTransactionRecord *)record {
    AuthorizedInvoiceInspectorViewController *vc = [[AuthorizedInvoiceInspectorViewController alloc] initWithNibName:@"AuthorizedInvoiceInspectorViewController" bundle:nil transactionRecord:record];
    
    [self.navigationController pushViewController:vc animated:YES];
    
}

@end
