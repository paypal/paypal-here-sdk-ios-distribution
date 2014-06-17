//
//  InvoiceViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "InvoiceViewController.h"
#import <PayPalHereSDK/PPHInvoiceItem.h>
@interface InvoiceViewController ()

@end

@implementation InvoiceViewController

- (id)initWithInvoice:(PPHInvoice *)invoice nibName: (NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.invoice = invoice;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    [self.itemsTable registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuseIdentifier"];
    self.itemsTable.layer.cornerRadius = 10;
    self.itemsTable.contentInset = UIEdgeInsetsMake(-60, 0, -60, 0);
    
    self.subtotal.layer.cornerRadius = 10;
    [self.subtotal setText: [NSString stringWithFormat:@"Subtotal: $%.2f", self.invoice.subTotal.doubleValue]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.itemsTable dequeueReusableCellWithIdentifier:@"reuseIdentifier" forIndexPath:indexPath];
    cell.textLabel.text = [(PPHInvoiceItem *)self.invoice.items[indexPath.row] name];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.invoice.items count];
}

@end
