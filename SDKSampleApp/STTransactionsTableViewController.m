//
//  STTransactionsTableViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/16/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "InvoicesManager.h"
#import "STTransactionsTableViewController.h"
#import "PaymentMethodViewController.h"
#import "PayPalHereSDK.h"

@interface STTransactionsTableViewController ()

@end

@implementation STTransactionsTableViewController

- (id)initWithStyle:(UITableViewStyle)style andDelegate: (id<InvoicesProtocal>) delegate
{
    self = [super initWithStyle:style];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Current Transactions";
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseIdentifier"];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [[InvoicesManager getCurrentTransactions] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    PPHInvoice *invoice = [[InvoicesManager getCurrentTransactions] objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Invoice total: %.2f", invoice.subTotal.doubleValue];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    [self.delegate purchaseWithInvoice:[[InvoicesManager getCurrentTransactions] objectAtIndex:indexPath.row]];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the transaction
        [InvoicesManager removeTransaction:[[InvoicesManager getCurrentTransactions] objectAtIndex:indexPath.row]];
        
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}



@end
