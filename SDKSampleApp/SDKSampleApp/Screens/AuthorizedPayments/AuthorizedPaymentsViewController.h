//
//  AuthorizedPaymentsViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/14/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AuthorizedPaymentsViewController : UIViewController
<
UITableViewDataSource,
UITableViewDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *authorizedPaymentsTableView;

@end
