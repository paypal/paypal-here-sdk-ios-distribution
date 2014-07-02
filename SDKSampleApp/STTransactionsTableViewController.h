//
//  STTransactionsTableViewController.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/16/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHInvoice.h>

@protocol InvoicesProtocal <NSObject>
@required
- (void) purchaseWithInvoice:(PPHInvoice *)invoice;
@end

@interface STTransactionsTableViewController : UITableViewController
@property (nonatomic, weak) id<InvoicesProtocal> delegate;
- (id)initWithStyle:(UITableViewStyle)style andDelegate: (id<InvoicesProtocal>) delegate;
@end
