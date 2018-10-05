//
//  TransactionOptionsViewController.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import "PaymentViewController.h"

@interface TransactionOptionsViewController : UIViewController
@property (nonatomic, weak, nullable) id<TransactionOptionsViewControllerDelegate> optionsDelegate;
@property (nonatomic,assign) PPRetailTransactionBeginOptions *transactionOptions;
@property (nonatomic,assign) NSMutableArray *formFactorArray;
-(void)setDelegate:(UIViewController *) delegateController;
@end
