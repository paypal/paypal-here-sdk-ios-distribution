//
//  SignatureViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import "SignatureViewController.h"
#import <PayPalHereSDK/PPHTransactionRecord.h>
#import <PayPalHereSDK/PayPalHereSDK.h>
#import "PaymentCompleteViewController.h"

@interface SignatureViewController () <
    PPHSignatureViewDelegate,
    UIAlertViewDelegate
>

@property (nonatomic,strong) PPHTransactionResponse* capturedPaymentResponse;

@end

@implementation SignatureViewController


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil transactionResponse:(PPHTransactionResponse*)capturedPayment
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.capturedPaymentResponse = capturedPayment;
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

-(void)signatureTouchesBegan
{
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
- (IBAction)onDonePressed:(id)sender
{
    
    // Let's provide the signature for this transaction.
    [[PayPalHereSDK sharedTransactionManager] finalizePaymentForTransaction:_capturedPaymentResponse.record
                        withSignature:self.signature.printableImage
                    completionHandler:^(PPHError *error) {
                        [self showPaymentCompeleteView:_capturedPaymentResponse];                        
                    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self showPaymentCompeleteView:_capturedPaymentResponse];
}


-(void) showPaymentCompeleteView:(PPHTransactionResponse *)response
{
    PaymentCompleteViewController* paymentCompleteViewController = [[PaymentCompleteViewController alloc]
                                                                    initWithNibName:@"PaymentCompleteViewController"
                                                                    bundle:nil
                                                                    forResponse:response];
    
    [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
    
}

@end
