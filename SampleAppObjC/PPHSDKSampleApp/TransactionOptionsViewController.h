//
//  TransactionOptionsViewController.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>

@interface TransactionOptionsViewController : UIViewController
/// Sets up the parameters for taking in Options from Payment View Controller
@property (weak, nonatomic) id delegate;
@property (weak, nonatomic) PPRetailTransactionBeginOptions *transactionOptions;
@property (weak, nonatomic) NSMutableArray *formFactorArray;
@end
