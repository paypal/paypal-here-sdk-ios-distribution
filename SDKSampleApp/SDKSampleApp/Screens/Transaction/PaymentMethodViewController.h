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
UITextFieldDelegate,
UIAlertViewDelegate,
PPHTransactionControllerDelegate,
PPHTransactionManagerDelegate
>


@end
