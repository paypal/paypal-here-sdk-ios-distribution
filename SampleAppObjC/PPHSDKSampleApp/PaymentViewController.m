//
//  PaymentViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/19/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "PaymentViewController.h"
#import "UIButton+CustomButton.h"
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import "NSString+Common.h"
#import "PaymentCompletedViewController.h"
#import "AuthCompletedViewController.h"
#import "PPRetailTransactionBeginOptions+SET_DEFAULT.h"
#import "TransactionOptionsViewController.h"
#import "OfflineModeViewController.h"

@interface PaymentViewController () <PPHRetailSDKAppDelegate,TransactionOptionsViewControllerDelegate,OfflineModeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UIButton *offlineModeButton;
@property (weak, nonatomic) IBOutlet UITextField *invAmount;
@property (weak, nonatomic) IBOutlet UIButton *createInvoiceBtn;
@property (weak, nonatomic) IBOutlet UITextView *createInvCodeView;
@property (weak, nonatomic) IBOutlet UIButton *createTxnBtn;
@property (weak, nonatomic) IBOutlet UITextView *createTxnCodeView;
@property (weak, nonatomic) IBOutlet UIButton *acceptTxnBtn;
@property (weak, nonatomic) IBOutlet UITextView *acceptTxnCodeView;
@property PPRetailTransactionContext *tc;
@property PPRetailInvoice *invoice;
@property NSString *transactionNumber;
@property PPRetailInvoicePaymentMethod paymentMethod;
@property NSString *currencySymbol;
@property NSMutableArray *formFactorArray;
@property PPRetailTransactionBeginOptions *options;
@property TransactionOptionsViewController *transactionOptionsViewController;
@property OfflineModeViewController *offlineModeViewController;
@property BOOL offlineMode;

@end

@implementation PaymentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setUpDefaultView];
    [self setUpUI];
    
    [PayPalRetailSDK setRetailSDKAppDelegate:self];
    // Set default options for transactions
    self.options = [PPRetailTransactionBeginOptions defaultOptions];
    
    // Initialize preferred form factor array
    self.formFactorArray = [[NSMutableArray alloc] init];
    
    // Check if online mode is On or Off
    self.offlineMode = [[PayPalRetailSDK transactionManager] getOfflinePaymentEnabled];
}

-(void) viewDidAppear:(BOOL)animated {
    [self.invAmount becomeFirstResponder];
}

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setUpDefaultView];
    NSUserDefaults *userDefaults =  [NSUserDefaults standardUserDefaults];
    self.currencySymbol = [userDefaults stringForKey:@"CURRENCY_SYMBOL"];
    [self.invAmount setPlaceholder:[NSString stringWithFormat:@"%@ 0.00",self.currencySymbol]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];

}

// This function intializes an invoice to be used for the transaction.  It simply takes the amount
// from the input and utilizes a single item generic order.  For extra items or invoice settings,
// simply modify/add them here so they are set.
- (IBAction)createInvoice:(id)sender {
    // Invoice initialization takes in the currency code. However, if the currency used to init doesn't
    // match the active merchant's currency, then an error will happen at payment time. Simply using
    // userDefaults to store the merchant's currency after successful initializeMerchant, and then use
    // it when initializing the invoice.
    NSUserDefaults *tokenDefault =  [NSUserDefaults standardUserDefaults];
    NSString *merchCurrency = [tokenDefault stringForKey:@"MERCH_CURRENCY"];
    PPRetailInvoice *mInvoice;
    if(![self.invAmount.text  isEqualToString:@""]) {
       mInvoice =  [[PPRetailInvoice alloc] initWithCurrencyCode: merchCurrency];
    } else {
        [self invokeAlert:@"Error" andMessage:@"Something happened during invoice initialization"];
        return;
    }
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.generatesDecimalNumbers = YES;
    NSDecimalNumber *price = (NSDecimalNumber*)[formatter numberFromString: [self.invAmount.text stringByReplacingOccurrencesOfString:self.currencySymbol withString:@""]];
    NSDecimalNumber *quantity = (NSDecimalNumber*)[formatter numberFromString: @"1"];
    [mInvoice addItem:@"My Order" quantity:quantity unitPrice:price itemId:123 detailId:nil];
    
    
    // The invoice Number is used for duplicate payment checking.  It should be unique for every
    // unique transaction attempt.  For payment resubmissions, simply use the same invoice number
    // to ensure that the invoice hasn't already been paid. For sample purposes, this app is
    // simply generating a random number to append to the string 'sdk2test'.

    mInvoice.number = [NSString stringWithFormat:@"sdk2test:%d",arc4random_uniform(99999)];
    if(mInvoice.itemCount > 0 && [mInvoice.total intValue] >= 1) {
        self.invoice = mInvoice;
        self.invAmount.enabled = NO;
        self.createInvoiceBtn.enabled = NO;
        [CustomButton buttonWasSelected:self.createInvoiceBtn];
        self.createTxnBtn.enabled = YES;
    } else {
        [self invokeAlert:@"Error" andMessage:[NSString stringWithFormat:@"Either there are no line items or the total amount is less than %@1",self.currencySymbol]];
        return;
    }
}

// This function does the createTransaction call to start the process with the current invoice.
- (IBAction)createTransaction:(id)sender {
    
    [PayPalRetailSDK.transactionManager createTransaction:self.invoice callback:^(PPRetailError *error, PPRetailTransactionContext *context) {
        self.tc = context;
       [CustomButton buttonWasSelected:self.createTxnBtn];
        self.createTxnBtn.enabled = NO;
        self.acceptTxnBtn.enabled = YES;
        
    }];
}

// This function will activate the reader by calling the begin method of TransactionContext.  This will
// activate the reader and have it show the payment methods available for payment.  The listeners are
// set in this function as well to allow for the listening of the user either inserting, swiping, or tapping
// their payment device.
- (IBAction)acceptTransaction:(id)sender {
    
    // This card presented listener is optional as the SDK will automatically continue when the card is
    // presented even if this listener is not implemented.
     __unsafe_unretained typeof(self) weakSelf = self;
    [self.tc setCardPresentedHandler:^(PPRetailCard *card) {
        [weakSelf.tc continueWithCard:card];
    }];
    
    [self.tc setCompletedHandler:^(PPRetailError *error, PPRetailTransactionRecord *record) {
        
        if(error != nil) {
            NSLog(@"Error Code: %@", error.code);
            NSLog(@"Error Message: %@", error.message);
            NSLog(@"Debug ID: %@", error.debugId);
            return;
        } else {
            NSLog(@"Txn ID: %@", record.transactionNumber);
            [weakSelf.navigationController popToViewController:weakSelf animated:false];
            weakSelf.transactionNumber = record.transactionNumber;
            weakSelf.paymentMethod =  record.paymentMethod;
        
            if(weakSelf.options.isAuthCapture) {
                [weakSelf goToAuthCompletedViewController];
            } else {
                [weakSelf goToPaymentCompletedViewController];
            }
        }
    }];
    
    if(self.offlineMode) {
        [self.tc setOfflineTransactionAdditionHandler:^(PPRetailError *error, PPRetailOfflineTransactionRecord *record) {
            if(error != nil) {
                NSLog(@"Error Code: %@", error.code);
                NSLog(@"Error Message: %@", error.message);
                NSLog(@"Debug ID: %@", error.debugId);
                return;
            } else {
                [weakSelf goToOfflinePaymentCompletedViewController];
            }
        }];
    }
    [self.tc beginPayment:self.options];
}

- (IBAction)offlinePaymentMode:(id)sender {
    [self performSegueWithIdentifier:@"offlineModeVC" sender:self];
}

- (IBAction)paymentOptions:(id)sender {
    [self performSegueWithIdentifier:@"transactionOptionsVC" sender:self];
}

-(void) goToAuthCompletedViewController {
    [self performSegueWithIdentifier:@"goToAuthCompletedView" sender:self];
}

-(void) goToPaymentCompletedViewController {
    [self performSegueWithIdentifier:@"goToPmtCompletedView" sender:self];
}

-(void) goToOfflinePaymentCompletedViewController {
    [self performSegueWithIdentifier:@"offlinePaymentCompletedVC" sender:self];
}

-(void) transactionOptionsController:(TransactionOptionsViewController *)controller options:(PPRetailTransactionBeginOptions *)options {
    self.options = options;
}

-(void)offlineModeController:(OfflineModeViewController *)controller offline:(BOOL)isOffline{
     self.offlineMode = isOffline;
}

-(void)setUpDefaultView{
    [self setUpTextFieldToolbar:_invAmount];
    [self customizeOfflineButton:self.offlineModeButton offline:self.offlineMode];
    self.createInvCodeView.text = @"mInvoice = [[PPRetailInvoice init] initWithCurrencyCode: @\"USD\"];";
    self.createTxnCodeView.text = @"[[PayPalRetailSDK transactionManager] createTransaction:self.invoice callback:^(PPRetailError *error, PPRetailTransactionContext *context) {\n // Set the transactionContext or handle the error \n self.tc = context \n }];";
    self.acceptTxnCodeView.text = @"[self.tc beginPayment:options];";
}

-(void)setUpUI{
    [CustomButton customizeButton:self.createInvoiceBtn];
    [CustomButton customizeButton:self.createTxnBtn];
    [CustomButton customizeButton:self.acceptTxnBtn];
}

-(void)customizeOfflineButton:(UIButton *)button offline:(BOOL)offline{
    if (offline){
        [button setTitle:@"ENABLED" forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 30, 0, 0)];
        [button setTitleColor:UIColor.greenColor forState:UIControlStateNormal];
        [[button imageView] setImage:[UIImage imageNamed:@"Arrow Right"]];
        [button setImageEdgeInsets:UIEdgeInsetsMake(0, button.frame.size.width - 10, 0, 0)];
    } else {
        [button setTitle:@"" forState:UIControlStateNormal];
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 30, 0, 0)];
        [button setTitleColor:UIColor.redColor forState:UIControlStateNormal];
        [[button imageView] setImage:[UIImage imageNamed:@"Arrow Right"]];
        [button setImageEdgeInsets:UIEdgeInsetsMake(0, button.frame.size.width - 10, 0, 0)];
    }
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if([segue.identifier isEqualToString:@"goToPmtCompletedView"]) {
        PaymentCompletedViewController *pmtCompletedViewController = (PaymentCompletedViewController *) segue.destinationViewController;
        pmtCompletedViewController.isCapture = NO;
        pmtCompletedViewController.transactionNumber = self.transactionNumber;
        pmtCompletedViewController.invoice = self.invoice;
        pmtCompletedViewController.paymentMethod = self.paymentMethod;
    }
    if([segue.identifier isEqualToString:@"goToAuthCompletedView"]) {
        AuthCompletedViewController *authCompletedViewController = (AuthCompletedViewController *) segue.destinationViewController;
        authCompletedViewController.authTransactionNumber = self.transactionNumber;
        authCompletedViewController.invoice = self.invoice;
        authCompletedViewController.paymentMethod = self.paymentMethod;
    }
    
    if ([segue.identifier isEqualToString:@"offlineModeVC"]){
        OfflineModeViewController *offlineModeViewController = (OfflineModeViewController *) segue.destinationViewController;
        [offlineModeViewController setDelegate: self];
        offlineModeViewController.offlineMode = self.offlineMode;
    }
    
    if ([segue.identifier isEqualToString:@"transactionOptionsVC"]) {
        TransactionOptionsViewController *transactionOptionsViewController = (TransactionOptionsViewController *) segue.destinationViewController;
        [transactionOptionsViewController setDelegate: self];
        transactionOptionsViewController.formFactorArray = self.formFactorArray;
        transactionOptionsViewController.transactionOptions = self.options;
    }
}

// Function to handle real-time changes in the invoice/payment amount text field.  The
// create invoice button is disabled unless there is a value in the box.
-(void) editingChanged:(UITextField *) textField {
    
    NSString *amountString = [textField.text currencyInputFormatting];
    textField.text = amountString;
    
    if([self.invAmount.text isEqualToString:@""]) {
        self.createInvoiceBtn.enabled = NO;
        return;
    }
    self.createInvoiceBtn.enabled = YES;
    
}

-(void) doneButtonAction {
    [self.view endEditing:true];
}

- (UINavigationController *)getCurrentNavigationController {
    return self.navigationController;
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

-(void)setUpTextFieldToolbar:(UITextField *)textfield{
    // init toolbar for keyboard
    UIToolbar *toolbar = [[UIToolbar alloc] init];
    toolbar.frame = CGRectMake(0, 0, self.view.frame.size.width, 30);
    //create left side empty space so that done button set on right side
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonAction)];
    [toolbar setItems:@[flexSpace, doneBtn]];
    [toolbar sizeToFit];
    //setting toolbar as inputAccessoryView
    textfield.inputAccessoryView = toolbar;
    // Setting up initial aesthetics.
    textfield.layer.borderColor =  [UIColor colorWithRed:0.0f/255.0f green:159.0f/255.0f blue:228.0f/255.0f alpha:1.0f].CGColor;
    [textfield addTarget:self action:@selector(editingChanged:) forControlEvents:UIControlEventEditingChanged];
}

@end
