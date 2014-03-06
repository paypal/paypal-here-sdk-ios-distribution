//
//  SignatureViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import "SignatureViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>
#import "PaymentCompleteViewController.h"

@interface SignatureViewController () <
    PPHSignatureViewDelegate,
    UIAlertViewDelegate
>

@property (nonatomic,strong) PPHTransactionRecord* capturedPaymentRecord;

@end

@implementation SignatureViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil transactionRecord:(PPHTransactionRecord*)capturedPayment
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.capturedPaymentRecord = capturedPayment;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.signature.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    UIView *parent = self.view;
    CGRect r = CGRectMake(5, 5, parent.frame.size.width - 10, parent.frame.size.height - 50);
    self.signature = [[PPHSignatureView alloc] initWithFrame:r];
    [parent addSubview:_signature];
}

-(void)signatureTouchesBegan {
    self.charge.hidden = YES;
}

-(void)signatureUpdated:(BOOL)isEmpty
{
    self.charge.enabled = !isEmpty;
    self.charge.hidden = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:self
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    
    [alertView show];
}

/*
 * When the done button is pressed let's send the signature to the SDK along with the payment record
 * to associate with this signature.  The SDK will record the signature to the service.
 */
- (IBAction)onDonePressed:(id)sender {
    
    // Let's provide the signature for this transaction.
    [[PayPalHereSDK sharedTransactionManager] finalizePaymentForTransaction:_capturedPaymentRecord
                        withSignature:self.signature.printableImage
                    completionHandler:^(PPHError *error) {
                        
                        if(error == nil) {
                            [self showAlertWithTitle:@"Payment Success" andMessage:[NSString stringWithFormat:@"Card payment finished successfully with transactionId: %@", _capturedPaymentRecord.transactionId]];
                        }
                        else {
                            [self showAlertWithTitle:@"Payment Success" andMessage:[NSString stringWithFormat:@"Card payment finished successfully but we failed to provide the signature.  TransacitonId: %@", _capturedPaymentRecord.transactionId]];
                        }
                        
                        
                    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    //[self.navigationController popToRootViewControllerAnimated:YES];
    [self showPaymentCompeleteView:_capturedPaymentRecord];
}


-(void) showPaymentCompeleteView:(PPHTransactionRecord *)record {
    
    PaymentCompleteViewController* paymentCompleteViewController = [[PaymentCompleteViewController alloc]
                                                                    initWithNibName:@"PaymentCompleteViewController"
                                                                    bundle:nil];
    paymentCompleteViewController.transactionRecord = record;
    [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
    
}

@end
