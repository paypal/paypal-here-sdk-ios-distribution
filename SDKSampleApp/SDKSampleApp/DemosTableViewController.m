//
//  DemosTableViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//
#define IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad

#import "DemosTableViewController.h"
#import "InvoiceViewController.h"
#import "TransactionViewController.h"
#import "SimpleTransactionViewController.h"

@interface DemosTableViewController ()
@property (nonatomic, strong) NSArray *demoNames;

@end

@implementation DemosTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        self.demoNames = @[@"Simple transaction", @"Restaurant App", @"Auth and Capture", @"Custom Card Reader Controls"];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseIdentifier"];
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
    return self.demoNames.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = self.demoNames[indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *vc;
    switch (indexPath.row) {
        case 0:
            vc = [[SimpleTransactionViewController alloc] init];
            // Simple Transaction View Controller
            break;
        case 1: {
            NSString *interfaceName = (IPAD) ? @"TransactionViewController_iPad" : @"TransactionViewController_iPhone";
            vc = [[TransactionViewController alloc] initWithNibName:interfaceName bundle:nil];
            break;
        }
        case 2:
            // Invoice
            vc = [[InvoiceViewController alloc] init];

        
        default:
            break;
    }
    
    [self.navigationController pushViewController:vc animated:YES];
}

@end
