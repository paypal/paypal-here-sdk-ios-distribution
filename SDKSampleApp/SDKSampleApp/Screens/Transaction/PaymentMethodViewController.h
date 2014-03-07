//
//  SAPaymentMethod.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHTransactionManager.h>

@interface PaymentMethodViewController : UIViewController
<
UIAlertViewDelegate,
PPHTransactionControllerDelegate,
PPHTransactionManagerDelegate
>

@property (strong, nonatomic) UIPageViewController *pageController;
@property (weak, nonatomic) IBOutlet UILabel *subtotalLabel;
@property (weak, nonatomic) IBOutlet UILabel *taxLabel;
@property (weak, nonatomic) IBOutlet UILabel *tipLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingTransactionSpinny;


- (IBAction)payWithManualEntryCard:(id)sender;
- (IBAction)payWithCashEntryCard:(id)sender;
- (IBAction)addTip:(id)sender;
- (IBAction)payWithCheckedInClient:(id)sender;

@end
