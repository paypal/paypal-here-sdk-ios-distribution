//
//  CCCFSPaymentMethodViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/20/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "CCCFSPaymentMethodViewController.h"
#import "PayPalHereSDK.h"

#import "PaymentMethodViewController.h"
#import "SignatureViewController.h"
#import "CheckedInCustomerCell.h"
#import "PaymentCompleteViewController.h"
#import "CheckedInCustomerViewController.h"
#import "ManualCardEntryViewController.h"
#import "CCCustomInputViewController.h"
#import "STAppDelegate.h"
#import "AuthorizationCompleteViewController.h"
#import "InvoicesManager.h"
#import "CCSwipersTableTableViewController.h"

enum swiperState : NSUInteger {
    kSwiperStateListening = 0,
    kSwiperStateOff = 1,
};

@interface CCCFSPaymentMethodViewController ()
@property (nonatomic,strong) PPHTransactionWatcher *transactionWatcher;
@property PPHTransactionResponse *transactionResponse;

@property BOOL waitingForCardSwipe;
@property BOOL doneWithPayScreen;
@property BOOL isCashTransaction;

@property (nonatomic, retain) IBOutlet UITextField *tipTextField;
@property (nonatomic, retain) IBOutlet UITextField *discountTextField;

@property (nonatomic, retain) IBOutlet UIButton *manualButton;
@property (nonatomic, retain) IBOutlet UIButton *checkinButton;
@property (nonatomic, retain) IBOutlet UIButton *cashButton;
@property (nonatomic, retain) IBOutlet UIButton *listenForSwipesButton;
@property (nonatomic, retain) IBOutlet UIButton *customInputButton;

@property (strong, nonatomic) UIPageViewController *pageController;
@property (weak, nonatomic) IBOutlet UILabel *subtotalLabel;
@property (weak, nonatomic) IBOutlet UILabel *taxLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingTransactionSpinny;

- (IBAction)payWithManualEntryCard:(id)sender;
- (IBAction)payWithCashEntryCard:(id)sender;
- (IBAction)payWithCheckedInClient:(id)sender;
- (IBAction)payWithCustomInput:(id)sender;
- (IBAction)listenForSwipes:(id)sender;
- (IBAction)startNewTransaction:(id)sender;

@end

@implementation CCCFSPaymentMethodViewController


-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.transactionWatcher = [[PPHTransactionWatcher alloc] initWithDelegate:self];
        self.waitingForCardSwipe = YES;
        self.doneWithPayScreen = NO;
        self.isCashTransaction = NO;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.manualButton.layer.cornerRadius = 10;
    self.checkinButton.layer.cornerRadius = 10;
    self.cashButton.layer.cornerRadius = 10;
    self.listenForSwipesButton.layer.cornerRadius = 10;
    self.customInputButton.layer.cornerRadius = 10;
    
    self.listenForSwipesButton.tag = kSwiperStateOff;
    
    self.tipTextField.delegate = self;
    self.discountTextField.delegate = self;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(startNewTransaction:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updatePaymentInformationLabels];
    
    [self.processingTransactionSpinny stopAnimating];
    self.processingTransactionSpinny.hidden = YES;
}

-(void)updatePaymentInformationLabels {
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHInvoice *invoice = tm.currentInvoice;
    self.tipTextField.text = [NSString stringWithFormat:@"%0.2f", [invoice.gratuity doubleValue]];
    self.discountTextField.text = [NSString stringWithFormat:@"%0.2f", [invoice.discountAmount doubleValue]];
    self.taxLabel.text = [NSString stringWithFormat:@"%0.2f", [invoice.tax doubleValue]];
    self.subtotalLabel.text = [NSString stringWithFormat:@"%0.2f", [invoice.subTotal doubleValue]];
    self.totalLabel.text = [NSString stringWithFormat:@"%0.2f", [[invoice.totalAmount amount] doubleValue]];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    
}

-(IBAction)payWithManualEntryCard:(id)sender
{
    ManualCardEntryViewController *cardEntryView = [[ManualCardEntryViewController alloc]
                                                    initWithNibName:@"ManualCardEntryViewController"
                                                    bundle:nil];
    [self.navigationController pushViewController:cardEntryView animated:YES];
}

-(IBAction)payWithCashEntryCard:(id)sender
{
    // Since this is a cash transaction, set this flag.
    // We will not be saving these transaction records since we would not perform refunds on cash transactions.
    self.isCashTransaction = YES;
    
    //For Cash the PPHTransactionManager will simply record the invoice to the backend.
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    
    [tm processPaymentWithPaymentType:ePPHPaymentMethodCash
            withTransactionController:self
                    completionHandler:^(PPHTransactionResponse *record) {
                        _doneWithPayScreen = YES;   //Let's exit the payment screen once they hit OK
                        self.transactionResponse = record;
                        [self showPaymentCompeleteView];
                        tm.ignoreHardwareReaders = NO;    //Back to the default running state.
                    }];
    
}

- (IBAction)payWithCustomInput:(id)sender {
    CCCustomInputViewController *vc = [[CCCustomInputViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

-(void) showPaymentCompeleteView
{
    if (!_isCashTransaction && _transactionResponse.record != nil) {
        STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Add the record into an array so that we can issue a refund later.
        [appDelegate.refundableRecords addObject:_transactionResponse.record];
    }
    
    PaymentCompleteViewController *paymentCompleteViewController = [[PaymentCompleteViewController alloc] initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:_transactionResponse];
    
    [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
}

-(void) showAuthorizationCompeleteView
{
    if (_transactionResponse.record != nil) {
        STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Add the record into an array so that we can issue a refund later.
        [appDelegate.authorizedRecords addObject:_transactionResponse.record];
    }
    
    AuthorizationCompleteViewController* vc = [[AuthorizationCompleteViewController alloc]
                                               initWithNibName:@"AuthorizationCompleteViewController"
                                               bundle:nil
                                               forAuthResponse:_transactionResponse];
    
    [self.navigationController pushViewController:vc animated:YES];
}

-(IBAction)payWithCheckedInClient:(id)sender
{
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.isMerchantCheckedin){
        UIAlertView *alert = [ [UIAlertView alloc] initWithTitle:@"Alert"
                                                         message:@"You are not checked-in. Please go to Settings and check-in first to take payments through this channel"
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil ];
        [alert show];
        return;
    }
    CheckedInCustomerViewController *checkedInCustomerView = nil;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        checkedInCustomerView = [[CheckedInCustomerViewController alloc]
                                 initWithNibName:@"CheckedInCustomerViewController_iPhone"
                                 bundle:nil];
    } else {
        checkedInCustomerView = [[CheckedInCustomerViewController alloc]
                                 initWithNibName:@"CheckedInCustomerViewController_iPad"
                                 bundle:nil];
    }
    
    [self.navigationController pushViewController:checkedInCustomerView animated:YES];
    
}

- (IBAction)listenForSwipes:(id)sender {
    CCSwipersTableTableViewController *vc = [[CCSwipersTableTableViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (_doneWithPayScreen)
        [self showPaymentCompeleteView];
}

#pragma mark PPHTransactionControllerDelegate
-(PPHTransactionControlActionType)onPreAuthorizeForInvoice:(PPHInvoice *)inv withPreAuthJSON:(NSString*) preAuthJSON
{
    NSLog(@"TransactionViewController: onPreAuthorizeForInvoice called");
    return ePPHTransactionType_Continue;
}

-(void)onPostAuthorize:(BOOL)didFail
{
    NSLog(@"TransactionViewController: onPostAuthorize called.  'authorize' %@ fail", didFail ? @"DID" : @"DID NOT");
}

#pragma mark UITableViewDataSource
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CheckedInCustomerCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CheckedInCustomerCellIdentifier"];
    if (cell == nil) {
        cell = [[CheckedInCustomerCell alloc] initWithStyle:UITableViewCellStyleDefault
                                            reuseIdentifier:@"CheckedInCustomerCellIdentifier@"];
    }
    cell.customerName.text = @"none";
    return cell;
}

#pragma mark -
#pragma mark PPHTransactionManagerDelegate overrides

/*
 * Called when the transaction manager wants to communicate certain events.
 */
-(void)onPaymentEvent:(PPHTransactionManagerEvent *) event
{
    if (event.eventType == ePPHTransactionType_Idle) {
        [self.processingTransactionSpinny stopAnimating];
        self.processingTransactionSpinny.hidden = YES;
    } else {
        [self.processingTransactionSpinny startAnimating];
        self.processingTransactionSpinny.hidden = NO;
    }
}

-(void)collectSignatureAndFinalizePurchaseWithRecord
{
    SignatureViewController *settings = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        settings = [[SignatureViewController alloc]
                    initWithNibName:@"SignatureViewController_iPhone"
                    bundle:nil
                    transactionResponse:_transactionResponse];
    } else {
        settings = [[SignatureViewController alloc]
                    initWithNibName:@"SignatureViewController_iPad"
                    bundle:nil
                    transactionResponse:_transactionResponse];
    }
    [self.navigationController pushViewController:settings animated:YES];
}


- (IBAction)startNewTransaction:(id)sender {
    PPHInvoice *invoice = [[PayPalHereSDK sharedTransactionManager] currentInvoice];
    [InvoicesManager addTransaction:invoice];
    [self.navigationController popToViewController:self.navigationController.viewControllers[1] animated:YES];
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    // Update the string in the text input
    NSMutableString* currentString = [NSMutableString stringWithString:textField.text];
    [currentString replaceCharactersInRange:range withString:string];
    // Strip out the decimal separator
    [currentString replaceOccurrencesOfString:@"." withString:@""
                                      options:NSLiteralSearch range:NSMakeRange(0, [currentString length])];
    // Generate a new string for the text input
    int currentValue = [currentString intValue];
    NSString* format = [NSString stringWithFormat:@"%%.%df", 2];
    double minorUnitsPerMajor = 100.0;
    NSString* newString = [NSString stringWithFormat:format, currentValue/minorUnitsPerMajor];
    textField.text = newString;
    
    return NO;
}

- (void) textFieldDidEndEditing:(UITextField *)textField {
    if (textField == self.tipTextField) {
        [[PayPalHereSDK sharedTransactionManager] currentInvoice].gratuity = [NSDecimalNumber decimalNumberWithString:textField.text];
    } else if (textField == self.discountTextField) {
        [[PayPalHereSDK sharedTransactionManager] currentInvoice].discountAmount = [NSDecimalNumber decimalNumberWithString:textField.text];
    }
    [self updatePaymentInformationLabels];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
    
	return YES;
    
}

@end
