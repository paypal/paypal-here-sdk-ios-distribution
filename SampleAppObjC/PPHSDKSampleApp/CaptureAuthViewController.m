//
//  CaptureAuthViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/20/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "CaptureAuthViewController.h"
#import "NSString+Common.h"
#import "PaymentCompletedViewController.h"

@interface CaptureAuthViewController ()
@property (weak, nonatomic) IBOutlet UITextField *captureAmount;
@property (weak, nonatomic) IBOutlet UIButton *captureAuthBtn;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;
@property (weak, nonatomic) IBOutlet UILabel *enterAmountLbl;
@property NSString *captureTransactionNumber;
@property NSDecimalNumber *capturedAmount;
@property NSDecimalNumber *gratuityAmt;
@property NSString *currencySymbol;
@end

@implementation CaptureAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // init toolbar for keyboard
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    //create left side empty space so that done button set on right side
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonAction)];
    [toolbar setItems:@[flexSpace, doneBtn]];
    [toolbar sizeToFit];
    //setting toolbar as inputAccessoryView
    self.captureAmount.inputAccessoryView = toolbar;
    // Setting up initial aesthetics.
    self.captureAmount.layer.borderColor =  [UIColor colorWithRed:0.0f/255.0f green:159.0f/255.0f blue:228.0f/255.0f alpha:1.0f].CGColor;
    [self.captureAmount addTarget:self action:@selector(editingChanged:) forControlEvents:UIControlEventEditingChanged];
    
    if(self.isTip) {
        self.enterAmountLbl.text = @"Enter a tip amount";
        [self.captureAuthBtn setTitle:@"Capture Tip" forState:UIControlStateNormal];
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [self.captureAmount becomeFirstResponder];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSUserDefaults *userDefaults =  [NSUserDefaults standardUserDefaults];
    self.currencySymbol = [userDefaults stringForKey:@"CURRENCY_SYMBOL"];
    [self.captureAmount setPlaceholder:[NSString stringWithFormat:@"%@ 0.00",self.currencySymbol]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)captureAuthorization:(id)sender {
    
    NSDecimalNumber *amountToCapture = [[NSDecimalNumber alloc] initWithInt:0];
    
    if([self.captureAmount.text isEqualToString:@""]) {
        [self invokeAlert:@"Error" andMessage:@"You need to enter a capture amount"];
        return;
    }
    self.activitySpinner.hidden = NO;
    [self.activitySpinner startAnimating];
    self.captureAuthBtn.enabled = NO;
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.generatesDecimalNumbers = YES;
    NSDecimalNumber *inputtedAmount = (NSDecimalNumber*)[formatter numberFromString: [self.captureAmount.text stringByReplacingOccurrencesOfString:self.currencySymbol withString:@""]];
    
        if(self.isTip) {
            amountToCapture = [self.invoice.total decimalNumberByAdding:inputtedAmount];
            self.gratuityAmt = inputtedAmount;
        } else {
            amountToCapture = inputtedAmount;
            self.gratuityAmt = 0;
        }

    [PayPalRetailSDK.transactionManager captureAuthorization:self.authTransactionNumber invoiceId:self.invoice.payPalId totalAmount:amountToCapture gratuityAmount:self.gratuityAmt currency:self.invoice.currency callback:^(PPRetailError *error, NSString *captureId) {
        if(error != nil) {
            NSLog(@"Error Code: %@",error.code);
            NSLog(@"Error Message: %@",error.message);
            NSLog(@"Debug ID Code: %@",error.debugId);
            [self.activitySpinner stopAnimating];
            return;
        }
        NSLog(@"Capture ID: %@",captureId);
        
        self.captureTransactionNumber = captureId;
        self.capturedAmount = amountToCapture;
        [self.activitySpinner stopAnimating];
        [self goToPaymentCompletedViewController];
    }];
}

- (UINavigationController *)getCurrentNavigationController {
    return self.navigationController;
}
     
-(void) goToPaymentCompletedViewController {
     [self performSegueWithIdentifier:@"goToPmtCompletedView" sender:self];
}

// Function to handle real-time changes in the invoice/payment amount text field.  The
// create invoice button is disabled unless there is value in the box.
-(void) editingChanged:(UITextField *) textField {
    
    NSString *amountString = [textField.text currencyInputFormatting];
    textField.text = amountString;
}


- (void)invokeAlert:(NSString *)title andMessage:(NSString *) message {
    UIAlertController * alert = [UIAlertController
                                 alertControllerWithTitle:title
                                 message:message
                                 preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* yesButton = [UIAlertAction
                                actionWithTitle:@"Yes"
                                style:UIAlertActionStyleDefault
                                handler:^(UIAlertAction * action) {
                                    //Handle your yes please button action here
                                }];
    
    UIAlertAction* noButton = [UIAlertAction
                               actionWithTitle:@"Cancel"
                               style:UIAlertActionStyleDefault
                               handler:^(UIAlertAction * action) {
                                   //Handle no, thanks button
                               }];
    
    //Add your buttons to alert controller
    [alert addAction:yesButton];
    [alert addAction:noButton];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) doneButtonAction {
    [self.view endEditing:YES];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     if([segue.identifier isEqualToString:@"goToPmtCompletedView"]) {
        PaymentCompletedViewController *pmtCompletedViewController = (PaymentCompletedViewController *) segue.destinationViewController;
         pmtCompletedViewController.isCapture = YES;
         pmtCompletedViewController.capturedAmount = self.capturedAmount;
         pmtCompletedViewController.paymentMethod = self.paymentMethod;
         pmtCompletedViewController.invoice = self.invoice;
        // For Auth-Capture, use the captureId returned by captureAuthorization as the transactionNumber for refunds
         pmtCompletedViewController.transactionNumber = self.captureTransactionNumber;
         pmtCompletedViewController.isTip = self.isTip;
         if(self.isTip) {
             pmtCompletedViewController.gratuityAmt = self.gratuityAmt;
         }
    }
}


@end
