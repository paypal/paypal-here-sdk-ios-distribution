//
//  PaymentViewController.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/19/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>

@protocol TransactionOptionsViewControllerDelegate <NSObject>
@required
-(void) transactionOptionsController :(UIViewController *)controller options:(PPRetailTransactionBeginOptions*)options;
@end

@protocol OfflineModeViewControllerDelegate <NSObject>
@required
-(void) offlineModeController :(UIViewController*)controller offline:(BOOL)isOffline;
@end

@interface PaymentViewController : UIViewController <TransactionOptionsViewControllerDelegate,OfflineModeViewControllerDelegate>

@end
