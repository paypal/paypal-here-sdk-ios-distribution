//
//  InvoiceViewController.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHInvoice.h>

@interface InvoiceViewController : UIViewController <UITableViewDelegate>
@property (nonatomic, weak) PPHInvoice *invoice;
@property (nonatomic, strong) IBOutlet UITableView *itemsTable;
@property (nonatomic, retain) IBOutlet UILabel *subtotal;

- (id)initWithInvoice:(PPHInvoice *)invoice nibName: (NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil;
@end
