//
//  CaptureViewController.m
//  RetailSDKTestApp
//
//  Created by Singeetham, Sreepada on 6/5/17.
//  Copyright © 2017 PayPal. All rights reserved.
//

#import "CaptureViewController.h"
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import <PayPalRetailSDK/PPRetailCaptureResponse.h>

@implementation CaptureViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    if (self.authorizationFromSegue) {
        self.authorizationIdField.text = self.authorizationFromSegue.authorizationId;
        self.authorizationIdField.enabled = NO;
        self.captureAmountField.text = [NSString stringWithFormat:@"%@",self.authorizationFromSegue.netAuthorizedAmount];
    }
}

-(IBAction)captureButtonPressed:(id)sender {
    if(![self.authorizationIdField.text isEqualToString:@""]) {
        NSString *authorizationId = self.authorizationIdField.text;
        NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithString:@"0.0"];
        if (![self.captureAmountField.text isEqualToString:@""]) {
            amount = [NSDecimalNumber decimalNumberWithString:self.captureAmountField.text];
        }
        [PayPalRetailSDK captureAuthorizedTransaction:authorizationId amount:amount completionHandler:^(PPRetailError *error, PPRetailCaptureResponse *response) {
            if (error == NULL) {
                NSString *line1 = [@"captureId: " stringByAppendingString:[response captureId]];
                NSString *line2 = [@"status: " stringByAppendingString:[response state]];
                NSString *line3 = [@"amount: " stringByAppendingString:[NSString stringWithFormat:@"%@", [response captureAmount]]];
                NSString *line4 = [@"transactionFee: " stringByAppendingString:[NSString stringWithFormat:@"%@", [response transactionFee]]];
                NSString *line5 = [@"currency: " stringByAppendingString:[response currency]];
            
                NSString *resultantString = [@[line1, line2, line3, line4, line5] componentsJoinedByString:@"\n"];
                self.statusLabel.text = resultantString;
            }
        }];
    }
}

@end
