//
//  PaymentCompletedViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/20/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "PaymentCompletedViewController.h"
#import "UIButton+CustomButton.h"


@interface PaymentCompletedViewController ()
@property (weak, nonatomic) IBOutlet UIButton *provideRefundBtn;
@property (weak, nonatomic) IBOutlet UILabel *successMsg;
@property (weak, nonatomic) IBOutlet UITextView *refundCodeViewer;
@property (weak, nonatomic) IBOutlet UIButton *skipRefund;
@property NSDecimalNumber *refundAmount;
@end

@implementation PaymentCompletedViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [CustomButton customizeButton:_provideRefundBtn];
    [CustomButton customizeButton:_skipRefund];
    self.refundCodeViewer.text = @"[tc beginRefund:YES amount:self.refundAmount];";
    if(self.isCapture) {
        if(self.isTip) {
            self.successMsg.text = [NSString stringWithFormat:@"Your tip of $%1$@ was added for a capture total of $%2$@ ",self.gratuityAmt, self.capturedAmount];
        } else {
            self.successMsg.text = [NSString stringWithFormat:@"Your capture of $%@ was successful", self.capturedAmount];
        }
        self.refundAmount = self.capturedAmount;
    } else {
        self.successMsg.text = [NSString stringWithFormat:@"Your payment was successful: $%@", self.invoice.total];
        self.refundAmount = self.invoice.total;
    }        
    [self.successMsg sizeToFit];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// This function will process the refund. You first have to create a TransactionContext, then set the appropriate
// listeners, and then call beginRefund. Calling beginRefund with true and the amount will first prompt
// if there's a card available or not. Based on that selection, the refund will process for the amount
// supplied and the completion handler will be called afterwards.
- (IBAction)provideRefund:(id)sender {

    [PayPalRetailSDK.transactionManager createRefundTransaction:self.invoice.payPalId transactionNumber:self.transactionNumber paymentMethod: self.paymentMethod callback:^(PPRetailError *error, PPRetailTransactionContext *context) {

        [context setCompletedHandler:^(PPRetailError *error, PPRetailTransactionRecord *record) {
            if(error != nil) {
                NSLog(@"Error Code: %@", error.code);
                NSLog(@"Error Message: %@", error.message);
                NSLog(@"Debug ID: %@", error.debugId);
                return;
            }
            NSLog(@"Refund ID: %@", record.transactionNumber);
            [self.navigationController popToViewController:self animated:false];
            [self skipRefund:nil];
        }];
        
        [context beginRefund:YES amount:self.refundAmount];
    }];
}

// If the 'No Thanks' button is selected, we direct back to the PaymentViewController
// so that more transactions can be run.
- (IBAction)skipRefund:(id)sender {
    [self performSegueWithIdentifier:@"goToPaymentsView" sender:self];
}


@end
