//
//  SimpleFSPaymentDelegate.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/20/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "SimpleFSPaymentDelegate.h"
#import "PaymentMethodViewController.h"

@implementation SimpleFSPaymentDelegate

- (NSString *) validateInvoiceForPayment:(PPHInvoice *)invoice {
    if (invoice.subTotal.doubleValue < 0.01 && invoice.subTotal.doubleValue > -0.01) {
        return @"You cannot specify amounts less than a penny.";
	}
    // Insert other verifications here
    
    return nil;
}

- (kSAFlow) purchase:(PPHInvoice *)invoice {
    if (![PayPalHereSDK activeMerchant]) {
        [STServices showAlertWithTitle:@"Bad State!" andMessage:@"The merchant hasn't been created yet?   We can't use the SDK until the merchant exists."];
        return kSAError;
    }
    
    // Create invoice by adding the items from the shopping cart.
    
    // Validate invoice for errors
    NSString *invoiceError = [self validateInvoiceForPayment:invoice];
    if (invoiceError) {
        [STServices showAlertWithTitle:@"Input Error" andMessage:invoiceError];
        return kSAError;
    }
    
    // Begin the purchase and forward to payment method
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    [tm beginPayment];
    tm.currentInvoice = invoice;
    return kSAFS;
}

@end
