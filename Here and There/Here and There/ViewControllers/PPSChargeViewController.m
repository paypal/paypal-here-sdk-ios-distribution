//
//  PPSChargeViewController.m
//  Here and There
//
//  Created by Metral, Max on 2/27/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHLocationTab.h>
#import "PPSChargeViewController.h"
#import "NimbusModels.h"
#import "PPSStyledView.h"
#import "PPSSignatureViewController.h"
#import "PPSProgressView.h"
#import "PPSAlertView.h"

@interface PPSChargeViewController () <
    UITableViewDelegate,
    PPHSimpleCardReaderDelegate,
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
@property (nonatomic,strong) PPHLocationTab *candidateTab;

@property (nonatomic,strong) NITableViewActions* actions;
@end

@implementation PPSChargeViewController

-(id)initWithInvoice:(PPHInvoice *)invoice andLocationWatcher:(PPHLocationWatcher *)watcher
{
    if ((self = [super init])) {
        self.invoice = invoice;
        self.watcher = [[PayPalHereSDK sharedLocalManager] watcherForLocationId:watcher.locationId withDelegate:self];
        self.cardWatcher = [[PPHCardReaderWatcher alloc] initWithSimpleDelegate:self];
        [self.navigationController setNavigationBarHidden:NO];
        [[PayPalHereSDK sharedCardReaderManager] activateReader:nil];
        
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

-(void)didStartReaderDetection:(PPHReaderType)readerType
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

#pragma mark -
#pragma mark Location Tab Events

-(void)locationWatcher:(PPHLocationWatcher *)watcher didCompleteUpdate:(NSArray *)openTabs wasModified:(BOOL)wasModified
{
    if (wasModified) {
        NSMutableArray *sectionedObjects = [@[
         @"People Here"
         ] mutableCopy];
        
        NSMutableDictionary *cellToTab = [[NSMutableDictionary alloc] init];
        for (PPHLocationTab *tab in openTabs) {
            NISubtitleCellObject *c = [NISubtitleCellObject objectWithTitle: tab.customerName subtitle:tab.tabId];
            // There must be a better way to do this.
            [cellToTab setObject:tab forKey: tab.tabId];
            [sectionedObjects addObject: [_actions attachToObject:c navigationSelector:@selector(confirm:)]];
        }
        
        self.cellToTabMap = cellToTab;
        self.tableView.dataSource = self.model = [[NITableViewModel alloc] initWithSectionedArray:sectionedObjects delegate:(id) [NICellFactory class]];
        [self.tableView reloadData];
    }
}

-(void)confirm: (NISubtitleCellObject*) row {
    PPHLocationTab *lt = [self.cellToTabMap objectForKey: row.subtitle];
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
        [[PayPalHereSDK sharedPaymentProcessor] beginTabPayment:self.candidateTab forInvoice:self.invoice completionHandler:^(PPHPaymentResponse *response) {
            [pg dismiss:YES];
            if (response.error != nil) {
                [PPSAlertView showAlertViewWithTitle:@"Error" message:response.error.localizedDescription buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
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
    [self.watcher updatePeriodically:2 withMaximumInterval:8];
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
