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

@interface PPSChargeViewController () <
    UITableViewDelegate,
    PPHSimpleCardReaderDelegate,
    PPHLocationWatcherDelegate
>
@property (nonatomic,strong) PPHInvoice *invoice;
@property (nonatomic,strong) UITableView *tableView;
@property (nonatomic,strong) NITableViewModel *model;
@property (nonatomic,strong) UIView *header;
@property (nonatomic,strong) PPHLocationWatcher *watcher;
@property (nonatomic,strong) PPHCardReaderWatcher *cardWatcher;

@property (nonatomic,strong) NITableViewActions* actions;
@end

@implementation PPSChargeViewController

-(id)initWithInvoice:(PPHInvoice *)invoice andLocationWatcher:(PPHLocationWatcher *)watcher
{
    if ((self = [super init])) {
        self.invoice = invoice;
        self.watcher = [[PayPalHereSDK sharedLocalManager] watcherForLocationId:watcher.locationId withDelegate:self];
        self.cardWatcher = [[PPHCardReaderWatcher alloc] initWithSimpleDelegate:self];
        [[PayPalHereSDK sharedCardReaderManager] beginTransaction:invoice];
        
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
                                                                        withCssClass: [PayPalHereSDK sharedCardReaderManager].availableDevices.count > 0 ? @".connected" : @".notconnected"
                                                                               andId:@"#tableHeader" withDOMTarget:self];
        self.model = [[NITableViewModel alloc] initWithSectionedArray:sectionedObjects delegate:(id) [NICellFactory class]];
    }
    return self;
}

-(void)dealloc
{
    [[PayPalHereSDK sharedCardReaderManager] endTransaction];
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
    
}

-(void)didDetectReaderDevice:(PPHCardReaderBasicInformation *)reader
{
    
}

-(void)didFailToReadCard
{
    
}

-(void)didDetectCardSwipeAttempt
{
    
}

-(void)didRemoveReader:(PPHReaderType)readerType
{
    
}

-(void)didReceiveCardReaderMetadata:(PPHCardReaderMetadata *)metadata
{
    
}

#pragma mark -
#pragma mark Location Tab Events

-(void)locationWatcher:(PPHLocationWatcher *)watcher didCompleteUpdate:(NSArray *)openTabs wasModified:(BOOL)wasModified
{
    if (wasModified) {
        NSMutableArray *sectionedObjects = [@[
         @"People Here"
         ] mutableCopy];
        
        for (PPHLocationTab *tab in openTabs) {
            [sectionedObjects addObject: [NISubtitleCellObject objectWithTitle: tab.customerName subtitle:tab.photoUrl.absoluteString]];
        }
        
        self.tableView.dataSource = self.model = [[NITableViewModel alloc] initWithSectionedArray:sectionedObjects delegate:(id) [NICellFactory class]];
        [self.tableView reloadData];
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
}

@end
