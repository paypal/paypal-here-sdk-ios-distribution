//
//  STViewController.h
//  SDKSampleApp
//
//  Created by Yarlagadda, Harish on 3/10/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHTransactionManager.h>

@interface ManualCardEntry : UIViewController
<
PPHTransactionControllerDelegate
>

@property (weak, nonatomic) IBOutlet UITextField *cardNumber;
@property (weak, nonatomic) IBOutlet UITextField *expMonth;
@property (weak, nonatomic) IBOutlet UITextField *expYear;
@property (weak, nonatomic) IBOutlet UITextField *cvv;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingTransactionSpinny;

@end
