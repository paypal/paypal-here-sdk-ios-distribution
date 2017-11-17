//
//  AuthorizedTransactionsTableViewController.h
//  RetailSDKTestApp
//
//  Created by Singeetham, Sreepada on 6/12/17.
//  Copyright © 2017 PayPal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import <PayPalRetailSDK/PPRetailRetrieveAuthorizedTransactionResponse.h>

@interface AuthorizedTransactionsTableViewController : UITableViewController
@property (strong, nonatomic) IBOutlet UITableView *tableContent;

@end
