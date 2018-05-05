//
//  PaymentCompletedViewController.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/20/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>

@interface PaymentCompletedViewController : UIViewController
@property (nonatomic, assign) PPRetailInvoice *invoice;
@property (nonatomic, assign) BOOL isCapture;
@property (nonatomic, assign) PPRetailInvoicePaymentMethod paymentMethod;
@property (nonatomic, assign) NSString *transactionNumber;
@property (nonatomic, assign) NSDecimalNumber *capturedAmount;
@property (nonatomic, assign) BOOL isTip;
@property (nonatomic, assign) NSDecimalNumber *gratuityAmt;
@end
