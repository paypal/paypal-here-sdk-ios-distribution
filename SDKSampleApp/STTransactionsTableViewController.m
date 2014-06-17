//
//  STTransactionsTableViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/16/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "CurrentTransactionManager.h"
#import "STTransactionsTableViewController.h"
#import "PaymentMethodViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface STTransactionsTableViewController ()

@end

@implementation STTransactionsTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
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
    return [[CurrentTransactionManager getCurrentTransactions] count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    PPHInvoice *invoice = [[CurrentTransactionManager getCurrentTransactions] objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSString stringWithFormat:@"Invoice total: %.2f", invoice.subTotal.doubleValue];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    [tm beginPayment];
    [tm setCurrentInvoice:[[CurrentTransactionManager getCurrentTransactions] objectAtIndex:indexPath.row]];

    PaymentMethodViewController *paymentMethod = nil;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        paymentMethod = [[PaymentMethodViewController alloc]
                         initWithNibName:@"PaymentMethodViewController_iPhone"
                         bundle:nil];
    }
    else {
        paymentMethod = [[PaymentMethodViewController alloc]
                         initWithNibName:@"PaymentMethodViewController_iPad"
                         bundle:nil];
    }
    
    [self.navigationController pushViewController:paymentMethod animated:YES];
    
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the transaction from disk
        [CurrentTransactionManager removeTransaction:[[CurrentTransactionManager getCurrentTransactions] objectAtIndex:indexPath.row]];
        
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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
