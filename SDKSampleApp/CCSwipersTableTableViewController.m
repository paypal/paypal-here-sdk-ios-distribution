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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    cell.editingAccessoryView = indicator;
    [indicator startAnimating];
    
    return cell;
}


-(void)didDetectReaderDevice: (PPHCardReaderBasicInformation*) reader {
    self.availableDevices = [[PayPalHereSDK sharedCardReaderManager] availableDevices];
    [self.tableView reloadData];
}

-(void)didRemoveReader: (PPHReaderType) readerType {
    self.availableDevices = [[PayPalHereSDK sharedCardReaderManager] availableDevices];
    [self.tableView reloadData];
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
