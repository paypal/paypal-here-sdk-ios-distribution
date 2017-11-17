//
//  EmvAutomationBridge.m
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/2/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "EmvAutomationBridge.h"
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import "PaymentViewController.h"
#import "AppDelegate.h"

@implementation EmvAutomationBridge
-(NSDictionary *)automationBridge:(PPAutomationBridge *)bridge receivedAction:(PPAutomationBridgeAction *)action {
    return [action resultFromTarget:self];
}

-(NSDictionary*)captureLogs:(NSDictionary*)args {
    return nil;
}

-(NSDictionary*)login:(NSDictionary*) args {
    NSString *env = args[@"env"];
    NSArray *sdkToken = @[
                          env,
                          args[@"access_token"],
                          args[@"expires"]?:[NSNull null],
                          args[@"refresh_url"]
                          ];
    NSString *base64 = [[NSJSONSerialization dataWithJSONObject:sdkToken options:0 error:nil] base64EncodedStringWithOptions:0];
    [PayPalRetailSDK initializeMerchant:base64 completionHandler:^(PPRetailError *error, PPRetailMerchant *merchant) {
        if (error) {
            [[PPAutomationBridge bridge] sendToConnectedClient:@{
                                                                 @"event": @"error",
                                                                 @"category": @"login",
                                                                 @"message": error.description
                                                                 }];
        } else {
            [[PPAutomationBridge bridge] sendToConnectedClient:@{
                                                                 @"event": @"transactionReady",
                                                                 }];
        }
        AppDelegate *app = (AppDelegate*) [UIApplication sharedApplication].delegate;
        PaymentViewController *tx = app.transactionViewController;
        [tx updateMerchantStatus];
        PPRetailInvoice *invoice = [[PPRetailInvoice alloc] initWithCurrencyCode:merchant.currency];
        [invoice addItem: @"Amount" quantity:PAYPALNUM(@"1") unitPrice:PAYPALNUM(@"2.50") itemId:@"1" detailId:nil];
        [invoice save:^(PPRetailError *error) {
            NSLog(@"error");
        }];
    }];
    return nil;
}

@end
