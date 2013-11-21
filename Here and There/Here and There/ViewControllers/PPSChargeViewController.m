//
//  PPSChargeViewController.m
//  Here and There
//
//  Created by Metral, Max on 2/27/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHLocationCheckin.h>
#import "PPSChargeViewController.h"
#import "NimbusModels.h"
#import "PPSStyledView.h"
#import "PPSSignatureViewController.h"
#import "PPSProgressView.h"
#import "PPSAlertView.h"

@interface PPSChargeViewController () <
    UITableViewDelegate,
    PPHCardReaderDelegate,
    PPHLocationWatcherDelegate,
    UIActionSheetDelegate
>
@property (nonatomic,strong) PPHInvoice *invoice;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NITableViewModel *model;
@property (nonatomic,strong) PPHLocationWatcher *watcher;
@property (nonatomic,strong) PPHCardReaderWatcher *cardWatcher;
@property (nonatomic,strong) UILabel *readerStatus;
@property (nonatomic,strong) NSDictionary *cellToTabMap;
@property (nonatomic,strong) PPHLocationCheckin *candidateTab;
@property (nonatomic,strong) PPHChipAndPinAuthResponse *activeAuthResponse;

@property (nonatomic,strong) NITableViewActions* actions;
@end

@implementation PPSChargeViewController

-(id)initWithInvoice:(PPHInvoice *)invoice andLocationWatcher:(PPHLocationWatcher *)watcher
{
    if ((self = [super init])) {
        self.invoice = invoice;
        if (watcher) {
            self.watcher = [[PayPalHereSDK sharedLocalManager] watcherForLocationId:watcher.locationId withDelegate:self];
        }
        self.cardWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
        [self.navigationController setNavigationBarHidden:NO];
        PPHReaderError err = [[PayPalHereSDK sharedCardReaderManager] activateReader:nil];
        if (err == ePPHReaderErrorLocationNotAvailable) {
            [PPSAlertView showAlertViewWithTitle:@"Reader Error" message: @"Location must be enabled." buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:^(PPSAlertView *alertView, UIButton *button, NSInteger index) {
                [alertView dismiss:NO];
                [self.navigationController popViewControllerAnimated:YES];
            }];            
        } else if (err != ePPHReaderErrorNone) {
            [PPSAlertView showAlertViewWithTitle:@"Reader Error" message:[NSString stringWithFormat:@"Couldn't open reader (%d)", err] buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:^(PPSAlertView *alertView, UIButton *button, NSInteger index) {
                [alertView dismiss:NO];
                [self.navigationController popViewControllerAnimated:YES];
            }];
        } else {
            [[PayPalHereSDK sharedCardReaderManager] beginTransaction:invoice];
        }
        
        self.tableView = [[UITableView alloc] init];
        self.actions = [[NITableViewActions alloc] initWithTarget:self];
        
        NSArray* sectionedObjects =
        [NSArray arrayWithObjects:
         @"People Here",
         nil
         ];
        self.tableView.tableFooterView = [[UIView alloc] init];
        NIStylesheet *stylesheet = [[PPSAppDelegate appDelegate].stylesheetCache stylesheetWithPath:@"css/chargePage.css"];
        self.tableView.tableHeaderView = [[PPSStyledView alloc] initWithJsonResource:@"views/chargePageHeader" andStylesheet: stylesheet
                                                                        withCssClass: nil
                                                                               andId:@"#tableHeader" withDOMTarget:self];
        self.model = [[NITableViewModel alloc] initWithSectionedArray:sectionedObjects delegate:(id) [NICellFactory class]];
        self.readerStatus.text = ([[PayPalHereSDK sharedCardReaderManager].availableDevices count] > 0) ? @"Reader connected" : @"Reader not connected";
    }
    return self;
}

-(void)dealloc
{
    [[PayPalHereSDK sharedCardReaderManager] deactivateReader:nil];
}

#pragma mark -
#pragma mark Card Reader Events
-(void)didCompleteCardSwipe:(PPHCardSwipeData *)card
{
    PPSSignatureViewController *pvc = [[PPSSignatureViewController alloc] initWithInvoice:self.invoice andCardData: card];
    [self.navigationController pushViewController:pvc animated:YES];
}

-(void)didStartReaderDetection:(PPHCardReaderBasicInformation*)readerType
{
    self.readerStatus.text = @"Detecting Device";
    [[(id)self.tableView.tableHeaderView dom] refreshView:self.readerStatus];
}

-(void)didDetectReaderDevice:(PPHCardReaderBasicInformation *)reader
{
    self.readerStatus.text = [NSString stringWithFormat:@"Detected %@", reader.friendlyName];
    [[(id)self.tableView.tableHeaderView dom] refreshView:self.readerStatus];    
}

-(void)didFailToReadCard
{
    self.readerStatus.text = @"Failed to read card.";
    [[(id)self.tableView.tableHeaderView dom] refreshView:self.readerStatus];    
}

-(void)didDetectCardSwipeAttempt
{
    self.readerStatus.text = @"Reading Swipe";
    [[(id)self.tableView.tableHeaderView dom] refreshView:self.readerStatus];
}

-(void)didRemoveReader:(PPHReaderType)readerType
{
    self.readerStatus.text = @"Reader Removed";
    [[(id)self.tableView.tableHeaderView dom] refreshView:self.readerStatus];
}

-(void)didReceiveCardReaderMetadata:(PPHCardReaderMetadata *)metadata
{
    self.readerStatus.text = [NSString stringWithFormat:@"Reader Serial %@", metadata.serialNumber];
    [[(id)self.tableView.tableHeaderView dom] refreshView:self.readerStatus];
}

-(void)didDetectUpgradeableReader:(PPHCardReaderBasicInformation *)reader withMessage:(NSString *)message isRequired:(BOOL)required isInitial:(BOOL)initial {
    __block PPSProgressView *pv = [PPSProgressView progressViewWithTitle:@"Software Upgrade" andMessage:@"For EMV Reader" withCancelHandler:^(PPSProgressView *progressView) {
        
    }];
    
#ifdef oldway
    [[PayPalHereSDK sharedCardReaderManager] beginUpgrade:nil completionHandler:^(PPHError *error) {
        NSLog(@"Update successful");
        
    } ];
#else
    [[PayPalHereSDK sharedCardReaderManager] beginUpgrade:reader];
    [pv dismiss:YES];
#endif
}

#pragma mark -
#pragma mark Chip and Pin Specific
-(void)didReceiveChipAndPinEvent:(PPHChipAndPinEvent *)event {
    __block __weak PPSChargeViewController *weakSelf = self;
    switch (event.eventType) {
        case ePPHChipAndPinEventCardInserted:
            self.activeAuthResponse = nil;
            self.readerStatus.text = @"Card Inserted";
            break;
        case ePPHChipAndPinEventWaitingForPin:
            self.readerStatus.text = @"Waiting for PIN";
            self.activeAuthResponse = nil;
            break;
        case ePPHChipAndPinEventPinDigitPressed:
            self.readerStatus.text = [NSString stringWithFormat:@"Digit Count: %d", ((PPHChipAndPinDigitEvent*)event).digits];
            break;
        case ePPHChipAndPinEventCardRemoved:
            self.readerStatus.text = @"Card Removed";
            self.activeAuthResponse = nil;
            break;
        case ePPHChipAndPinEventPinIncorrect:
            self.readerStatus.text = @"Incorrect Pin";
            break;
        case ePPHChipAndPinEventPinVerified:
            self.readerStatus.text = @"Correct Pin!";
            break;
        case ePPHChipAndPinEventAuthRequired:
            [[PayPalHereSDK sharedPaymentProcessor] beginChipAndPinAuthorization: (PPHChipAndPinAuthEvent*) event forInvoice:self.invoice completionHandler:^(PPHChipAndPinAuthResponse *response) {
                weakSelf.activeAuthResponse = response;
#ifdef oldway
                [[PayPalHereSDK sharedCardReaderManager] continueTransaction:response];
#else
                //Surely there's something to do?
                
#endif
            }];
            break;
        case ePPHChipAndPinEventApproved:
        {
            self.readerStatus.text = @"Approved";
            [[PayPalHereSDK sharedPaymentProcessor] finalizeChipAndPin: (PPHChipAndPinEventWithEmv*)event withAuth:self.activeAuthResponse forInvoice:self.invoice completionHandler:^(PPHCardChargeResponse *response) {
                if (response.error.isCancelError) { return; }
                if (response.error) {
                    [weakSelf handleTxError: response];
                } else {
                    weakSelf.readerStatus.text = @"Completed";
                    weakSelf.activeAuthResponse = nil;
                    [weakSelf.navigationController popToRootViewControllerAnimated:YES];
                }
            }];
            break;
        }
        case ePPHChipAndPinEventCardDeclined:
        case ePPHChipAndPinEventDeclined:
            self.readerStatus.text = @"Declined";
            break;
        default:
            NSLog(@"%@", event);
    }
}

-(void)handleTxError: (PPHCardChargeResponse*)response
{
    NSString *msg = response.error.localizedDescription;
    // These message are crap, just an example.
    switch (response.error.errorCategory) {
        case ePPHErrorCategoryRetry:
            msg = [NSString stringWithFormat: @"Your transaction failed, please try again. Reference code %@.", response.error.correlationId?:@"unavailable"];
            break;
        case ePPHErrorCategoryAmbiguous:
        case ePPHErrorCategoryUnknown:
        case ePPHErrorCategoryData:
            msg = [NSString stringWithFormat: @"An unknown error has occurred. Reference code %@.", response.error.correlationId?:@"unavailable"];
            break;
        case ePPHErrorCategoryBuyerDeclined:
            msg = [NSString stringWithFormat: @"The payment has been declined. Reference code %@.", response.error.correlationId?:@"unavailable"];
            break;
        case ePPHErrorCategorySellerDeclined:
            msg = [NSString stringWithFormat: @"There is a problem with your merchant account. Reference code %@.", response.error.correlationId?:@"unavailable"];
            break;
        case ePPHErrorCategoryOutage:
            msg = [NSString stringWithFormat: @"We were unable to contact the server to complete payment. Reference code %@.", response.error.correlationId?:@"unavailable"];
            break;
        default:
            break;
    }
    [PPSAlertView showAlertViewWithTitle:@"Payment Failed" message: msg buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
}

#pragma mark -
#pragma mark Location Tab Events

-(void)locationWatcher:(PPHLocationWatcher *)watcher didCompleteUpdate:(NSArray *)openTabs wasModified:(BOOL)wasModified
{
    if (wasModified) {
        NSMutableArray *sectionedObjects = [@[
         @"People Here"
         ] mutableCopy];
        
        NSMutableDictionary *cellToTab = [[NSMutableDictionary alloc] init];
        for (PPHLocationCheckin *tab in openTabs) {
            NISubtitleCellObject *c = [NISubtitleCellObject objectWithTitle: tab.customerName subtitle:tab.checkinId];
            // There must be a better way to do this.
            [cellToTab setObject:tab forKey: tab.checkinId];
            [sectionedObjects addObject: [_actions attachToObject:c navigationSelector:@selector(confirm:)]];
        }
        
        self.cellToTabMap = cellToTab;
        self.tableView.dataSource = self.model = [[NITableViewModel alloc] initWithSectionedArray:sectionedObjects delegate:(id) [NICellFactory class]];
        [self.tableView reloadData];
    }
}

-(void)confirm: (NISubtitleCellObject*) row {
    PPHLocationCheckin *lt = [self.cellToTabMap objectForKey: row.subtitle];
    self.candidateTab = lt;
    UIActionSheet *uia = [[UIActionSheet alloc]
                          initWithTitle: [NSString stringWithFormat:@"Really bill %@ %@?", lt.customerName, [self.invoice.totalAmount stringValue]]
                          delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:@"OK" otherButtonTitles: nil];
    [uia showInView:self.view];
}

-(void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != actionSheet.cancelButtonIndex) {
        PPSProgressView *pg = [PPSProgressView progressViewWithTitle:@"Processing Payment" andMessage:nil withCancelHandler:^(PPSProgressView *progressView) {
            
        }];
        [[PayPalHereSDK sharedPaymentProcessor] beginCheckinPayment:self.candidateTab forInvoice:self.invoice completionHandler:^(PPHPaymentResponse *response) {
            [pg dismiss:YES];
            if (response.error != nil) {
                NSString *msg = response.error.localizedDescription;
                // These message are crap, just an example.
                switch (response.error.errorCategory) {
                    case ePPHErrorCategoryRetry:
                        msg = [NSString stringWithFormat: @"Your transaction failed, please try again. Reference code %@.", response.error.correlationId?:@"unavailable"];
                        break;
                    case ePPHErrorCategoryAmbiguous:
                    case ePPHErrorCategoryUnknown:
                    case ePPHErrorCategoryData:
                        msg = [NSString stringWithFormat: @"An unknown error has occurred. Reference code %@.", response.error.correlationId?:@"unavailable"];
                        break;
                    case ePPHErrorCategoryBuyerDeclined:
                        msg = [NSString stringWithFormat: @"The payment has been declined. Reference code %@.", response.error.correlationId?:@"unavailable"];
                        break;
                    case ePPHErrorCategorySellerDeclined:
                        msg = [NSString stringWithFormat: @"There is a problem with your merchant account. Reference code %@.", response.error.correlationId?:@"unavailable"];
                        break;
                    case ePPHErrorCategoryOutage:
                        msg = [NSString stringWithFormat: @"We were unable to contact the server to complete payment. Reference code %@.", response.error.correlationId?:@"unavailable"];
                        break;
                    default:
                        break;
                }
                [PPSAlertView showAlertViewWithTitle:@"Error" message:msg buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
            } else {
                [self.watcher stopPeriodicUpdates];
                self.watcher = nil;
                [self.navigationController popToRootViewControllerAnimated:YES];
            }
        }];
    }
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.view addSubview:self.tableView];
    [self.dom registerView:self.tableView withCSSClass:nil andId:@"#table"];
    self.tableView.delegate = [self.actions forwardingTo:self];
    self.tableView.dataSource = self.model;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    // Comment this out if you want to reduce log messages to help debug something in particular
    //[self.watcher updatePeriodically:2 withMaximumInterval:8];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.watcher stopPeriodicUpdates];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    self.tableView.frame = self.view.frame;
    self.tableView.tableHeaderView.frame = self.tableView.bounds;
    [self.dom refresh];
    [[(id)self.tableView.tableHeaderView dom] refresh];
}

@end
