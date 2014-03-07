//
//  SAPaymentMethod.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//



#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHTransactionManager.h>
#import <PayPalHereSDK/PPHTransactionRecord.h>
#import <PayPalHereSDK/PPHTransactionWatcher.h>

#import "PaymentMethodViewController.h"
#import "SignatureViewController.h"
#import "AddTipViewController.h"
#import "CheckedInCustomerCell.h"
#import "PaymentCompleteViewController.h"
#import "CheckedInCustomerViewController.h"
#import "STAppDelegate.h"

@interface PaymentMethodViewController ()
@property (nonatomic,strong) PPHTransactionWatcher *transactionWatcher;
@property BOOL waitingForCardSwipe;
@property BOOL doneWithPayScreen;
@property PPHTransactionResponse *transactionResposne;

@end

@implementation PaymentMethodViewController

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
		self.transactionWatcher = [[PPHTransactionWatcher alloc] initWithDelegate:self];
        self.waitingForCardSwipe = YES;
        self.doneWithPayScreen = NO;
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
}

-(void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //NSLocale *locale = [NSLocale currentLocale];
    
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHInvoice *invoice = tm.currentInvoice;
    NSString *subTotalStr = [invoice.subTotal description];
    NSString *totalStr = [[invoice.totalAmount amount] description];
    NSString *tipStr = [invoice.gratuity description];
    NSString *totalTaxStr = [invoice.tax description];
    
    self.subtotalLabel.text = subTotalStr;
    self.totalLabel.text = totalStr;
    self.tipLabel.text = tipStr;
    self.taxLabel.text = totalTaxStr;
    
    [self.processingTransactionSpinny stopAnimating];
    self.processingTransactionSpinny.hidden = YES;
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    
}

-(IBAction)payWithManualEntryCard:(id)sender
{
    // Setup the manually entered card data
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:9];
    [comps setYear:2019];
    
    PPHCardNotPresentData *manualCardData = [[PPHCardNotPresentData alloc] init];
    manualCardData.cardNumber = @"4111111111111111";
    manualCardData.cvv2 = @"408";
    manualCardData.expirationDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    
    //Now, take a payment with it
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    
    //[tm beginPaymentWithAmount:[PPHAmount amountWithString:@"33.00" inCurrency:@"USD"] andName:@"FixedAmountPayment"];
    tm.manualEntryOrScannedCardData = manualCardData;
    
    
    [tm processPaymentWithPaymentType:ePPHPaymentMethodKey
            withTransactionController:self
                    completionHandler:^(PPHTransactionResponse *record) {
                        _doneWithPayScreen = YES;   //Let's exit the payment screen once they hit OK
                        self.transactionResposne = record;
                        [self showPaymentCompeleteView];
                        
                    }];
}

-(IBAction)payWithCashEntryCard:(id)sender
{
    
    //For Cash the PPHTransactionManager will simply record the invoice to the backend.
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    
    [tm processPaymentWithPaymentType:ePPHPaymentMethodCash
            withTransactionController:self
                    completionHandler:^(PPHTransactionResponse *record) {
                        _doneWithPayScreen = YES;   //Let's exit the payment screen once they hit OK
                        self.transactionResposne = record;
                        [self showPaymentCompeleteView];
                        tm.ignoreHardwareReaders = NO;    //Back to the default running state.
                    }];

}

-(void) showPaymentCompeleteView
{
     PaymentCompleteViewController* paymentCompleteViewController = [[PaymentCompleteViewController alloc]
                                                    initWithNibName:@"PaymentCompleteViewController"
                                                    bundle:nil];
    paymentCompleteViewController.transactionResponse = _transactionResposne;
    [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
    
}

-(IBAction)payWithCheckedInClient:(id)sender
{
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    if(!appDelegate.isMerchantCheckedin){
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
    }
    else {
        checkedInCustomerView = [[CheckedInCustomerViewController alloc]
                         initWithNibName:@"CheckedInCustomerViewController_iPad"
                         bundle:nil];
    }
    
    [self.navigationController pushViewController:checkedInCustomerView animated:YES];
    
}

-(void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message
{
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:self
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    
    [alertView show];
}

#pragma mark UIAlertViewDelegate
-(void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if(_doneWithPayScreen)
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

-(void)onPaymentEvent:(PPHTransactionManagerEvent *) event
{
     if(event.eventType == ePPHTransactionType_Idle) {
         [self.processingTransactionSpinny stopAnimating];
         self.processingTransactionSpinny.hidden = YES;
     }
     else {
         [self.processingTransactionSpinny startAnimating];
         self.processingTransactionSpinny.hidden = NO;
     }
     
     NSLog(@"Our local instance of PPHTransactionWatcher picked up a PPHTransactionManager event notification: <%@>", event);
     if(event.eventType == ePPHTransactionType_CardDataReceived && self.waitingForCardSwipe)  {
     
         self.waitingForCardSwipe = NO;
     
         //Now ask to authorize (and take) payment.
         [[PayPalHereSDK sharedTransactionManager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe
                                                       withTransactionController:self
                                                               completionHandler:^(PPHTransactionResponse *response) {
                                                                   self.transactionResposne = response;
                                                                   if(response.error) {
                                                                       [self showPaymentCompeleteView];
                                                                   }
                                                                   else {
                                                                       // Is a signature required for this payment?  If so
                                                                       // then let's collect a signature and provide it to the SDK.
                                                                       if(response.isSignatureRequiredToFinalize) {
                                                                           [self collectSignatureAndFinalizePurchaseWithRecord];
                                                                       }
                                                                       else {
                                                                           // All done.  Tell the user the good news.
                                                                           //Let's exit the payment screen once they hit OK
                                                                           _doneWithPayScreen = YES;
                                                                           [self showPaymentCompeleteView];
                                                                       }
         
                                                                   }
                                                               }];
     }
}

-(void)collectSignatureAndFinalizePurchaseWithRecord
{
    
    SignatureViewController *settings = nil;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        settings = [[SignatureViewController alloc]
                    initWithNibName:@"SignatureViewController_iPhone"
                    bundle:nil
                    transactionResponse:_transactionResposne];
    }
    else {
        settings = [[SignatureViewController alloc]
                    initWithNibName:@"SignatureViewController_iPad"
                    bundle:nil
                    transactionResponse:_transactionResposne];
    }
    
    [self.navigationController pushViewController:settings animated:YES];
}

- (IBAction)addTip:(id)sender
{
    AddTipViewController *addTipVC = [[AddTipViewController alloc]
                    initWithNibName:@"AddTipViewController"
                    bundle:nil
                    forInvoice:[[PayPalHereSDK sharedTransactionManager] currentInvoice]];
    
    
    [self.navigationController pushViewController:addTipVC animated:YES];
}

@end
