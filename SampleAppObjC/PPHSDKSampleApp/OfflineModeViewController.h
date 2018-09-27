//
//  OfflineModeViewController.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import "PaymentViewController.h"

@interface OfflineModeViewController : UIViewController
@property (nonatomic, weak, nullable) id<OfflineModeViewControllerDelegate> offlineDelegate;
@property (nonatomic, assign) BOOL offlineMode;
-(void)setDelegate:(UIViewController *) delegateController;
@end
