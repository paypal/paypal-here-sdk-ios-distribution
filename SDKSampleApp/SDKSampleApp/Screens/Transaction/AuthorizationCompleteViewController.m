//
//  AuthorizationResultViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 5/13/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "AuthorizationCompleteViewController.h"
#import "PayPalHereSDK.h"
#import "STAppDelegate.h"

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
    [super viewWillAppear:animated];
    
    self.navigationItem.hidesBackButton = YES;

    PPHInvoice * invoice = _authResponse.record.invoice;
    
    NSString *totalStr = [[invoice.totalAmount amount] description];
    self.invoiceAmountLabel.text = totalStr;
    _invoiceNumberLabel.text = [NSString stringWithFormat: @"Invoice Id : %@", invoice.paypalInvoiceId];
    
    if (_authResponse.error == nil) {
        self.authResultLabel.text = @"Authorization Successful";
    
        if (_authResponse.record.transactionId != nil) {
            _invoiceNumberLabel.text = [NSString stringWithFormat: @"Transaction Id : %@", _authResponse.record.transactionId];
        } else {
            _invoiceNumberLabel.text = [NSString stringWithFormat: @"Invoice Id : %@", _authResponse.record.payPalInvoiceId];
        }
    } else {
        //self.authResultLabel.text = @"Authorization Declined";
        self.authResultLabel.text = [NSString stringWithFormat: @"Authorization Declined With Error : %@", _authResponse.error.description];
    }
    
    _activitySpinner.hidden = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onDone:(id)sender {
    [self.navigationController popToViewController:self.navigationController.viewControllers[1] animated:YES];
}

- (IBAction)onCaptureNow:(id)sender {
    
    _activitySpinner.hidden = NO;
    [_activitySpinner startAnimating];
    _doneButton.enabled = NO;
    _captureButton.enabled = NO;
    self.authResultLabel.text = @"Capturing payment ...";
    
    [[PayPalHereSDK sharedTransactionManager] capturePaymentForAuthorization:_authResponse.record
                                                       withCompletionHandler:^(PPHTransactionResponse *response) {
                                                           [_activitySpinner stopAnimating];
                                                           _activitySpinner.hidden = YES;
                                                           _doneButton.enabled = YES;
                                                           
                                                           if(!response.error) {
                                                               self.authResultLabel.text = @"Capture Successful";
                                                               
                                                               NSString *ourInvoiceId = _authResponse.record.invoice.paypalInvoiceId;
                                                               
                                                               //Remove this record from our list of records that need captured.
                                                               STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
                                                               for(PPHTransactionRecord *record in appDelegate.authorizedRecords) {
                                                                   if(NSOrderedSame == [ourInvoiceId caseInsensitiveCompare:record.invoice.paypalInvoiceId]) {
                                                                       [appDelegate.authorizedRecords removeObject:record];
                                                                       break;
                                                                   }
                                                               }
                                                               
                                                               //Place this capture record in the list of records that are refundable
                                                               [appDelegate.refundableRecords addObject:response.record];
                                                           } else {
                                                               self.authResultLabel.text = @"Capture Failed";
                                                               _captureButton.enabled = YES;
                                                           }
                                                       }];
}



@end
