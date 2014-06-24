//
//  CCSwipersTableTableViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/20/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#define readerKey @"readerKey"
#define cellKey @"cellKey"

#import "CCSwipersTableTableViewController.h"
#import "STServices.h"
#import "STAppDelegate.h"
#import "AuthorizationCompleteViewController.h"
#import "PaymentCompleteViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>

@interface CCSwipersTableTableViewController ()
@property (nonatomic, strong) PPHCardReaderWatcher *cardWatcher;
@property (nonatomic, strong) NSArray *availableDevices;
@property (nonatomic, strong) NSMutableDictionary *activeReader;
@end

@implementation CCSwipersTableTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.cardWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
    [[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
    
    self.availableDevices = [[PayPalHereSDK sharedCardReaderManager] availableDevices];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseIdentifier"];
    
    self.activeReader = [[NSMutableDictionary alloc] init];
}
-(void)viewWillDisappear:(BOOL)animated {
    [[PayPalHereSDK sharedCardReaderManager] endMonitoring:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) showAuthorizationCompeleteView: (PPHTransactionResponse *)response
{
    if (response.record != nil) {
        STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Add the record into an array so that we can issue a refund later.
        [appDelegate.authorizedRecords addObject:response.record];
    }
    
    AuthorizationCompleteViewController* vc = [[AuthorizationCompleteViewController alloc]
                                               initWithNibName:@"AuthorizationCompleteViewController"
                                               bundle:nil
                                               forAuthResponse:response];
    
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) showPaymentCompeleteView : (PPHTransactionResponse *) response
{
    if (response.record != nil) {
        STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Add the record into an array so that we can issue a refund later.
        [appDelegate.refundableRecords addObject:response.record];
    }
    
    PaymentCompleteViewController *paymentCompleteViewController = [[PaymentCompleteViewController alloc] initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:response];
    
    [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
}



-(void)didDetectReaderDevice: (PPHCardReaderBasicInformation*) reader {
    self.availableDevices = [[PayPalHereSDK sharedCardReaderManager] availableDevices];
    [self.tableView reloadData];
}

-(void)didRemoveReader: (PPHReaderType) readerType {
    self.availableDevices = [[PayPalHereSDK sharedCardReaderManager] availableDevices];
    [self.tableView reloadData];
}


-(void)didDetectCardSwipeAttempt {
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [self.activeReader[cellKey] setEditingAccessoryView:indicator];
    [indicator startAnimating];
}

-(void)didCompleteCardSwipe:(PPHCardSwipeData*)card {
    // Clear out reader stuff
    [[PayPalHereSDK sharedCardReaderManager] deactivateReader:self.activeReader[readerKey]];
    [self.activeReader[cellKey] setAccessoryView:nil];
    [self.activeReader[cellKey] setHighlighted:NO];
    [self.activeReader removeAllObjects];
    
    
    [[PayPalHereSDK sharedTransactionManager] setEncryptedCardData:card];
    
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (appDelegate.paymentFlowIsAuthOnly) {
        
        [[PayPalHereSDK sharedTransactionManager] authorizePaymentWithPaymentType:ePPHPaymentMethodSwipe
                                                            withCompletionHandler:^(PPHTransactionResponse *response) {
                                                                [self showAuthorizationCompeleteView:response];
                                                                [[PayPalHereSDK sharedCardReaderManager] endMonitoring:YES];
                                                            }];
    } else {
        [[PayPalHereSDK sharedTransactionManager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe
                                                      withTransactionController:nil
                                                              completionHandler:^(PPHTransactionResponse *response) {
                                                                  [self showPaymentCompeleteView:response];
                                                                  [[PayPalHereSDK sharedCardReaderManager] endMonitoring:YES];

                                                              }];
    }
}

-(void)didFailToReadCard {
    [STServices showAlertWithTitle:@"Error" andMessage:@"Failed to read card. Please try again."];
    [self.activeReader[cellKey] setEditingAccessoryView:nil];
}

-(void)didReceiveCardReaderMetadata: (PPHCardReaderMetadata*) metadata {
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.availableDevices count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    cell.textLabel.text = [self.availableDevices[indexPath.row] family];
    cell.editingAccessoryType = UITableViewCellAccessoryCheckmark;

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    UITableViewCell *currentCell = self.activeReader[cellKey];
    
    if (self.activeReader) {
        [[PayPalHereSDK sharedCardReaderManager] deactivateReader:self.activeReader[readerKey]];
        [currentCell setEditing:NO animated:YES];
        [currentCell setHighlighted:NO];
    }
    if (cell == currentCell) {
        [self.activeReader removeAllObjects];
        return;
    }
    
    [cell setEditing:YES animated:YES];
    [self.activeReader setObject:self.availableDevices[indexPath.row] forKey:readerKey];
    [self.activeReader setObject:cell forKey:cellKey];
    
    [[PayPalHereSDK sharedCardReaderManager] activateReader:self.activeReader[readerKey]];
}



@end
