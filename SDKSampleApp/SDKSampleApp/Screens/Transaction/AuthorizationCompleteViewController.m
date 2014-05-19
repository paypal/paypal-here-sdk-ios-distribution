//
//  AuthorizationResultViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/13/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "AuthorizationCompleteViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>

@interface AuthorizationCompleteViewController ()
@property (strong, nonatomic) PPHTransactionResponse *authResponse;
@property (strong, nonatomic) NSDecimalNumberHandler *formatter;
@end

@implementation AuthorizationCompleteViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
           forAuthResponse:(PPHTransactionResponse *)authorizationResponse {
    
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.authResponse = authorizationResponse;
        self.formatter = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                                                scale:2
                                                                     raiseOnExactness:NO
                                                                      raiseOnOverflow:NO
                                                                     raiseOnUnderflow:NO
                                                                  raiseOnDivideByZero:NO];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    PPHInvoice * invoice = _authResponse.record.invoice;
    
    NSString *totalStr = [[invoice.totalAmount amount] description];
    self.invoiceAmountLabel.text = totalStr;
    _invoiceNumberLabel.text = [NSString stringWithFormat: @"Invoice Id : %@", invoice.paypalInvoiceId];
    
    if (_authResponse.error == nil) {
        self.authResultLabel.text = @"Authorization Successful";
        /*
        if (_transactionResponse.record.transactionId != nil) {
            self.paymentDetails.text = [NSString stringWithFormat: @"Transaction Id : %@", _transactionResponse.record.transactionId];
        } else {
            _invoiceNumberLabel.text = [NSString stringWithFormat: @"Invoice Id : %@", _transactionResponse.record.payPalInvoiceId];
        }
         */
    }
    else {
        self.authResultLabel.text = @"Authorization Declined";
        //self.paymentDetails.text = [NSString stringWithFormat: @"Error : %@", _transactionResponse.error.description];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onDone:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(IBAction)onCaptureNow:(id)sender {
    //Hmm.
}

@end
