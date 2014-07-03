//
//  TransactionViewController.h
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/19/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PayPalHereSDK.h>
#import "STServices.h"

@protocol PaymentProtocol <NSObject>
@required
- (kSAFlow) purchase:(PPHInvoice *)invoice;
@end

@interface TransactionViewController : UIViewController <UITableViewDataSource>
- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil aDelegate: (id) delegate;
- (void) purchaseWithInvoice:(PPHInvoice *)invoice;

@property (nonatomic, strong) id<PaymentProtocol> delegate;
@end


