//
//  CheckedInCustomerViewController.h
//  SDKSampleApp
//
//  Created by Yarlagadda, Harish on 3/5/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHTransactionManager.h>
#import <PayPalHereSDK/PPHLocationWatcher.h>

@interface CheckedInCustomerViewController : UIViewController
<
UITableViewDataSource,
UITableViewDelegate,
PPHLocationWatcherDelegate,
PPHTransactionControllerDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic,strong) NSString *checkinLocationId;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingTransactionSpinny;

@end