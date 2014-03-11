//
//  CheckedInCustomerViewController.m
//  SDKSampleApp
//
//  Created by Yarlagadda, Harish on 3/5/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHLocationCheckin.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>
#import <PayPalHereSDK/PPHTransactionWatcher.h>


#import "CheckedInCustomerViewController.h"
#import "CheckedInCustomerCell.h"
#import "STAppDelegate.h"

@interface CheckedInCustomerViewController ()
@property (nonatomic,strong) NSMutableArray *checkedInClients;
@property (nonatomic,strong) PPHLocationWatcher *locationWatcher;
@property (assign, nonatomic)BOOL doneWithPayScreen;
@end


@implementation CheckedInCustomerViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
        self.checkinLocationId = appDelegate.merchantLocation.locationId;
        self.locationWatcher = [[PayPalHereSDK sharedLocalManager] watcherForLocationId:self.checkinLocationId withDelegate:self];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"Calling updateNow on Location Watcher to get the current checked in clients for the location ID: %@ ",self.checkinLocationId);
    
    self.processingTransactionSpinny.hidden=YES;
}

-(void)viewDidUnload
{
    [super viewDidUnload];
    [self.locationWatcher stopPeriodicUpdates];
}


-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // If we are becoming visible then let's ask
    // the location watcher to send us periodic updates.  This will
    // let us know when people check in or out of our store.
    _locationWatcher.delegate = self;
    [_locationWatcher updatePeriodically:20 withMaximumInterval:60];
}

-(void)viewWillDisappear:(BOOL)animated {
    
    // If we are becoming invisible then let's ask
    // the location watcher to stop sending us periodic updates.  Also
    // clear out the delegate.
    _locationWatcher.delegate = nil;
    [_locationWatcher stopPeriodicUpdates];
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
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

-(void)takePaymentUsingCheckinClient:(PPHLocationCheckin*)checkinMember
{
    self.processingTransactionSpinny.hidden=NO;
    [self.processingTransactionSpinny startAnimating];
    
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    [tm setCheckedInClient:checkinMember];
    [tm processPaymentWithPaymentType:ePPHPaymentMethodPaypal
            withTransactionController:self
                    completionHandler:^(PPHTransactionResponse *record) {
                        _doneWithPayScreen = YES;   //Let's exit the payment screen once they hit OK
                        [self.processingTransactionSpinny stopAnimating];
                        self.processingTransactionSpinny.hidden=YES;
                        if(record.error) {
                            NSString *message = [NSString stringWithFormat:@"Payment using checkin Failed with an error: %@", record.error.apiMessage];
                            [self showAlertWithTitle:@"Payment Failed" andMessage:message];
                        }
                        else {
                            PPHTransactionResponse *localTransactionResponse = record;
                            PPHTransactionRecord *transactionRecord = localTransactionResponse.record;
                            NSString *message = [NSString stringWithFormat:@"Cash Entry finished successfully with transactionId: %@", transactionRecord.transactionId];
                            [self showAlertWithTitle:@"Payment Success" andMessage:message];
                        }
                        tm.ignoreHardwareReaders = NO;    //Back to the default running state.
                    }];
    
}


#pragma mark UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(self.doneWithPayScreen){
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

#pragma mark PPHTransactionControllerDelegate
-(PPHTransactionControlActionType)onPreAuthorizeForInvoice:(PPHInvoice *)inv withPreAuthJSON:(NSString*) preAuthJSON
{
    NSLog(@"TransactionViewController: onPreAuthorizeForInvoice called");
    return ePPHTransactionType_Continue;
}

-(void)onPostAuthorize:(BOOL)didFail
{
    NSLog(@"TransactionViewController: onPostAuthorize called.  'authorize' %@ fail", didFail ? @"DID" : @"DID NOT");
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.checkedInClients count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CheckedInCustomerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckedInCustomerCellIdentifier"];
    if (cell == nil) {
        cell = [[CheckedInCustomerCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:@"CheckedInCustomerCellIdentifier"];
    }
    PPHLocationCheckin *client = [self.checkedInClients objectAtIndex:indexPath.row];
    cell.imageView.image = [UIImage imageNamed:@"default_image.jpg"];;
        
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData *imgData = [NSData dataWithContentsOfURL:client.photoUrl];
        if (imgData) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIImage *actualImage = [UIImage imageWithData:imgData];
                CheckedInCustomerCell *c = (CheckedInCustomerCell *)[self.tableView cellForRowAtIndexPath:indexPath];
                c.imageView.image = actualImage;
                [c.imageView setNeedsDisplay];
            });
        }
    });
    
    // load the name of the checked in client
    cell.textLabel.text = client.customerName;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PPHLocationCheckin *client = [self.checkedInClients objectAtIndex:indexPath.row];
    if(nil != client){
        NSLog(@"Calling takePaymentUsingCheckinClient with the checkedin client: %@",client.customerName);
        [self takePaymentUsingCheckinClient:client];
    }else{
        NSLog(@"Oops! Selected row has no checkeding client..");
    }
}

#pragma mark PPHLocationWatcherDelegate
-(void)locationWatcher:(PPHLocationWatcher *)watcher didCompleteUpdate:(NSArray *)openTabs wasModified:(BOOL)wasModified
{
    NSLog(@"Got the response didCompleteUpdate from Location Watcher with list of checked-in clients. No. of clients: %d",[openTabs count]);
    self.checkedInClients = [[NSMutableArray alloc] initWithArray:openTabs];
    [self.tableView reloadData];
}

-(void)locationWatcher: (PPHLocationWatcher*) watcher didDetectNewTab: (PPHLocationCheckin*) checkin
{
    NSLog(@"Got the new checked in client after did the update. Need to update the rows");
}

-(void)locationWatcher: (PPHLocationWatcher*) watcher didDetectRemovedTab: (PPHLocationCheckin*) checkin
{
    NSLog(@"One of the checked in client checked out. Need to update the rows");
}

-(void)locationWatcher: (PPHLocationWatcher*) watcher didReceiveError: (PPHError*) error
{
    NSLog(@"Oops got the error while looking for checked in clients..");
}


@end
