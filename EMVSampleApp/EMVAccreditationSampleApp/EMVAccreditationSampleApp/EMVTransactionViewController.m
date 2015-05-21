//
//  EMVTransactionViewController.m
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 Curam, Abhay. All rights reserved.
//

#import "EMVTransactionViewController.h"
#import "EMVSalesHistoryViewController.h"
#import "PayPalHereSDK.h"
#import "AppDelegate.h"

@interface EMVTransactionViewController ()
@property (strong, nonatomic) PPHCardReaderWatcher *cardReaderWatcher;
@property (strong, nonatomic) UIAlertView *updateRequiredAlertDialog;
@property (strong, nonatomic) UIAlertView *retryContactlessAlertDialog;
@property (nonatomic) BOOL showReaderUpdateAlert;
@property (nonatomic, strong) PPHInvoice *currentInvoice;
@property (nonatomic, strong) PPHTransactionManager *transactionManager;
@property (nonatomic, assign) PPHPaymentMethod paymentMethod;
@property (copy) PPHContactlessListenerTimeoutHandler timeoutCompletionHandler;
@property (nonatomic, assign) BOOL cardInserted;
@property (nonatomic, assign) BOOL chargeButtonPressed;
@end

@implementation EMVTransactionViewController

#pragma mark -
#pragma mark UIViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.cardReaderWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
    }
    self.currentInvoice = nil;
    [[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.transactionAmountField.delegate = self;
    self.chargeButton.layer.cornerRadius = 10;
    self.salesHistoryButton.layer.cornerRadius = 10;
    self.updateTerminalButton.layer.cornerRadius = 10;
    [self enableUpdateTerminalButton:NO];
    self.transactionManager = [PayPalHereSDK sharedTransactionManager];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (BOOL)isAmountValid {
    NSCharacterSet *blockedChars = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    if ([self.transactionAmountField.text rangeOfCharacterFromSet:blockedChars].location != NSNotFound) {
        return NO;
    }
    return YES;
}

#pragma mark -
#pragma mark IBActions

-(IBAction)transactionAmountFieldUpdated:(id)sender {
    [self updatePaymentFlow];
}

- (IBAction)transactionAmountFieldReturned:(id)sender {
    [sender resignFirstResponder];
}

- (IBAction)chargeButtonPressed:(id)sender {
    self.chargeButtonPressed = YES;
    [_transactionAmountField resignFirstResponder];
    if (self.cardInserted) {
        self.cardInserted = NO;
        self.paymentMethod = ePPHPaymentMethodChipCard;
        [self processPayment];
    } else {
        if ([self getDecimalAmountFromString:self.transactionAmountField.text]) {
            [[PayPalHereSDK sharedTransactionManager] activateReaderForPayment];    //Start scanning for contactless and other 'active' types of payments
        } else {
            [self showAlertWithTitle:@"Invalid Amount" andMessage:@"Please enter a valid numerical amount."];
        }
    }
}

- (IBAction)salesHistoryButtonPressed:(id)sender {
    EMVSalesHistoryViewController *vc = [[EMVSalesHistoryViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (IBAction)updateTerminalButtonPressed:(id)sender {
    [self beginReaderUpdate];
}


#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return [self canPerformTransaction];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updatePaymentFlow];
}


#pragma mark -
#pragma mark PPHCardReaderDelegate Implementation

-(void)didRemoveReader:(PPHReaderType)readerType {
    self.emvConnectionStatus.textColor = [UIColor redColor];
    self.emvConnectionStatus.text = @"No EMV device paired, please connect one before transacting";
}

-(void)didDetectReaderDevice:(PPHCardReaderMetadata *)reader {
    self.showReaderUpdateAlert = YES;
    [self updateStatusText];
}

-(void)didReceiveCardReaderMetadata:(PPHCardReaderMetadata *)metadata {
    [self updateStatusText];
}

-(void) didReceiveChipAndPinEvent:(PPHChipAndPinEvent *)event {
    switch (event.eventType) {
        case ePPHChipAndPinEventCardInserted:
            self.cardInserted = YES;
            break;
            
        default:
            break;
    }
}
#pragma mark -
#pragma mark PPHTransactionControllerDelegate

-(void)onContactlessListenerTimeout:(PPHContactlessListenerTimeoutHandler)completionHandler {
    self.timeoutCompletionHandler = completionHandler;
    [self showContactlessTimeoutRetryAlertDialog];
}

-(PPHTransactionControlActionType)onPreAuthorizeForInvoice:(PPHInvoice *)inv withPreAuthJSON:(NSMutableDictionary*) preAuthJSON {
    return ePPHTransactionType_Continue;
}

-(void)onPostAuthorize:(BOOL)didFail {
}

-(UINavigationController *)getCurrentNavigationController {
    return self.navigationController;
}

- (void)onUserPaymentMethodSelected:(PPHPaymentMethod) paymentMethod {
    self.paymentMethod = paymentMethod;
    
    // Note that many EMV applications do not collect tip once the user
    // has tapped their card.  However, for card inserts or swipes asking
    // for a tip is then more popular.  Consider this when designing your application.
    
    // For this demo, let's just trigger the capture of payment.
    if (self.chargeButtonPressed) {
        self.chargeButtonPressed = NO;
        [self processPayment];
    }
}

#pragma mark -
#pragma mark Helpers

-(void)showContactlessTimeoutRetryAlertDialog {
    self.retryContactlessAlertDialog = [[UIAlertView alloc] initWithTitle:@"Contactless Timed Out" message:nil delegate:self cancelButtonTitle:@"Cancel Transaction" otherButtonTitles:@"Retry", @"Insert,Swipe", nil];
    [self.retryContactlessAlertDialog show];
}

- (void)updateStatusText {
    if ([self isUpdateRequired]) {
        if (self.showReaderUpdateAlert) {
            [self showUpdateRequiredAlertDialog];
        }
        [self displayConnectionStatusWithText:@"Update card reader!" andStatus:NO];
        [self enableUpdateTerminalButton:YES];
    } else {
        [self displayConnectionStatusWithText:@"EMV device connected and ready!" andStatus:YES];
    }
}

- (void)updatePaymentFlow {
    //Let's update our single item invoice with the new amount if updated. Storing the shopping cart
    //invoice as a property
    if (self.currentInvoice == nil) {
        if (![self.transactionAmountField.text isEqualToString:@""]) {
            self.currentInvoice = [self invoiceFromAmountString:self.transactionAmountField.text];
            [self.transactionManager beginPaymentUsingSDKUIWithInvoice:self.currentInvoice transactionController:self];
        }
    } else {
        if (![self.transactionAmountField.text isEqualToString:@""]) {
            PPHAmount *amount = [PPHAmount amountWithString:self.transactionAmountField.text];
            [self.currentInvoice removeAllItems];
            [self.currentInvoice addItemWithId:@"Purchase" detailId:@"" name:@"accreditationTestTransactionItem" quantity:[NSDecimalNumber one] unitPrice:amount.amount taxRate:nil taxRateName:nil];
        } else {
            //user emptied out field so nil out the invoice
            self.currentInvoice = nil;
        }
    }

}

- (PPHInvoice *)invoiceFromAmountString:(NSString *)amountString {
    
    NSDecimalNumber *decimalAmount = [self getDecimalAmountFromString:amountString];
    if (!decimalAmount) {
        return nil;
    }

    PPHAmount *amount = [PPHAmount amountWithDecimal:decimalAmount];

    PPHInvoice *invoice = [[PPHInvoice alloc] init];
    [invoice addItemWithId:@"Purchase"
                      name:@"accreditationTestTransactionItem"
                  quantity:[NSDecimalNumber one]
                 unitPrice:amount.amount
                   taxRate:nil taxRateName:nil];

    return invoice;
}

- (NSDecimalNumber *)getDecimalAmountFromString:(NSString *)amountStr {
    NSDecimalNumber *decimalAmount = [[NSDecimalNumber alloc]
                                      initWithString:amountStr];
    
    if(NSOrderedSame == [[NSDecimalNumber notANumber] compare: decimalAmount]) {
        return nil;
    }
    return decimalAmount;
}

- (void)processPayment {
    if (![self canPerformTransaction]) {
         [self showAlertWithTitle:@"No EMV Data" andMessage:@"Please make sure your EMV device is ready to take payments."];
        return;
    }

    

    if (!([PayPalHereSDK activeMerchant].payPalAccount.availablePaymentTypes & ePPHAvailablePaymentTypeChip)) {
        [self showAlertWithTitle:@"Payment Failure" andMessage:@"Unfortunately you can not take EMV payments, please call PayPal and get the appropriate permissions."];
        return;
    }

    __weak typeof(self) weakSelf = self;
    [self.transactionManager processPaymentUsingSDKUIWithPaymentType:self.paymentMethod completionHandler:^(PPHTransactionResponse *response) {
        
        //Whether we get a transaction response or not, lets get the EMVSDK rolling fresh
        //again, clear out out our current invoice and get rid of the current amount.
        weakSelf.currentInvoice = nil;
        weakSelf.transactionAmountField.text = @"";
        
        if(response) {
            if (!response.error && response.record.transactionId) {
                [weakSelf saveTransactionRecordForRefund:response.record];
            }
            else if(response.error.code == kPPHLocalErrorBadConfigurationPaymentAmountOutOfBounds)  {
                // This happens when the user is attempting to charge an amount that's outside
                // of the allowed bounds for this merchant.  Different merchants have different
                // min and max amounts they can charge.
                //
                // Your app can check these bounds before kicking off the payment (and eventually
                // getting this error).  To do that, please check the PPHPaymentLimits object found
                // via [[[PayPalHereSDK activeMerchant] payPalAccount] paymentLimits].
                NSLog(@"The app attempted to charge an out of bounds amount.");
                NSLog(@"Dev Message: %@", [response.error.userInfo objectForKey:@"DevMessage"]);
                [weakSelf showAlertWithTitle:@"Amount is out of bounds" andMessage:nil];
            }
            
        }
        [weakSelf.navigationController popToViewController:weakSelf animated:YES];
    }];
}

- (void)saveTransactionRecordForRefund:(PPHTransactionRecord *)record {
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    // Add the record into an array so that we can issue a refund later.
    [appDelegate.transactionRecords addObject:record];
    PPHAmount *zeroRefund = [PPHAmount amountWithString:@"0" inCurrency:record.invoice.totalAmount.stringValue];
    [appDelegate.refunds addObject:zeroRefund];
}

- (void)showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    
    [alertView show];
}

-(void)displayConnectionStatusWithText:(NSString *)statusText andStatus:(BOOL)ready {
    if (ready) {
        self.emvConnectionStatus.textColor = [UIColor blueColor];
    } else {
        self.emvConnectionStatus.textColor = [UIColor redColor];
    }
    self.emvConnectionStatus.text = statusText;
}

-(void)enableUpdateTerminalButton:(BOOL) enable {
    self.updateTerminalButton.hidden = !enable;
    self.updateTerminalButton.enabled = enable;
}


-(void)showUpdateRequiredAlertDialog {
    self.showReaderUpdateAlert = NO;
    self.updateRequiredAlertDialog = [[UIAlertView alloc] initWithTitle:@"Software Update Required"
                                                                message:@"Update Now?"
                                                               delegate:self
                                                      cancelButtonTitle:@"Not Now"
                                                      otherButtonTitles:@"OK", nil];
    
    [self.updateRequiredAlertDialog show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.updateRequiredAlertDialog) {
        if (buttonIndex != alertView.cancelButtonIndex) {
            [self beginReaderUpdate];
        }
        
        self.updateRequiredAlertDialog = nil;
    }
    else if (alertView == self.retryContactlessAlertDialog) {
        if (buttonIndex == alertView.cancelButtonIndex) {
            self.timeoutCompletionHandler(ePPHContactlessTimeoutActionCancelTransaction);
        } else {
            if (buttonIndex == 1) {
                self.timeoutCompletionHandler(ePPHContactlessTimeoutActionContinueWithContactless);
            }
            if (buttonIndex == 2) {
                self.timeoutCompletionHandler(ePPHContactlessTimeoutActionContinueWithContact);
            }
        }
    }
}

-(void)beginReaderUpdate {
    [[PayPalHereSDK sharedCardReaderManager] beginReaderUpdateUsingSDKUI_WithViewController:self
                                                                          completionHandler:^(BOOL success, NSString *message) {
                                                                              
                                                                              [self softwareUpdateCompleteWithStatus:success andMessage:message];
                                                                          }];
}

-(void)softwareUpdateCompleteWithStatus:(BOOL)success andMessage:(NSString *)message {
    [self enableUpdateTerminalButton:!success];
    [self showAlertWithTitle:[NSString stringWithFormat:@"Software Update %@", (success) ? @"Complete" : @"Failed"] andMessage:message];
}

-(BOOL)canPerformTransaction {
    return [[PayPalHereSDK sharedCardReaderStateMonitor].availableReader isReadyToTransact];
}

-(BOOL)isUpdateRequired {
    return [[PayPalHereSDK sharedCardReaderStateMonitor].availableReader upgradeIsManadatory];
}


@end
