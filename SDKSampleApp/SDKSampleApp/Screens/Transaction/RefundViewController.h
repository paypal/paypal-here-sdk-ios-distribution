//
//  RefundViewController.h
//  SDKSampleApp
//
//  Created by Chandrashekar,Sathyanarayan on 3/13/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RefundViewController : UIViewController
<
UITableViewDataSource,
UITableViewDelegate,
UIAlertViewDelegate
>

@property (weak, nonatomic) IBOutlet UITableView *refundTableView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingRefundSpinny;

@end
