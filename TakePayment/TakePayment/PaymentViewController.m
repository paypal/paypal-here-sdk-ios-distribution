//
//  PaymentViewController.m
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import "PaymentViewController.h"
#import "PaymentCompleteViewController.h"
#import "AppDelegate.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface PaymentViewController ()<
    UIAlertViewDelegate,
    UITextFieldDelegate,
    PPHTransactionControllerDelegate,
    PPHCardReaderDelegate,
    PPHTransactionManagerDelegate
>

@property (nonatomic, strong) UILabel *cardReaderStatus;
@property (nonatomic, strong) UITextField *amountTextField;
@property (nonatomic, strong) UIButton *enableContactlessButton;
@property (nonatomic, strong) PPHCardReaderWatcher *cardReaderWatcher;
@property (nonatomic, strong) PPHTransactionWatcher *transactionWatcher;
@property (nonatomic, strong) PPHInvoice *invoice;

@property (nonatomic) BOOL promptedForSoftwareUpdate;
@property (nonatomic, strong) UIAlertView *softwareUpgradeAlert;

@end

@implementation PaymentViewController

- (instancetype)init {
    if (self = [super init]) {
        self.cardReaderWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
        self.transactionWatcher = [[PPHTransactionWatcher alloc] initWithDelegate:self];
    }
    return self;
}

- (void)loadView {
    [super loadView];
   
    CGRect viewFrame = self.view.frame;
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    // Enter Amount Label
    UILabel *enterAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake((viewFrame.size.width - 200)/2, (viewFrame.size.height - 150)/2, 200, 50)];
    [enterAmountLabel setText:@"Enter an amount"];
    [enterAmountLabel setFont:[UIFont systemFontOfSize:15]];
    [enterAmountLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:enterAmountLabel];
    
    
    // Card Reader Status
    self.cardReaderStatus = [[UILabel alloc] initWithFrame:CGRectMake((viewFrame.size.width - 400)/2, (viewFrame.size.height + 150)/2, 400, 50)];
    [self.cardReaderStatus setFont:[UIFont systemFontOfSize:14]];
    [self.cardReaderStatus setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.cardReaderStatus];
    
    
    // Amount Text Field
    self.amountTextField = [[UITextField alloc] initWithFrame:CGRectMake((viewFrame.size.width - 100)/2, (viewFrame.size.height - 50)/2, 100, 40)];
    [self.amountTextField setPlaceholder:@"1.00"];
    [self.amountTextField setTextAlignment:NSTextAlignmentRight];
    [self.amountTextField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.amountTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    self.amountTextField.delegate = self;
    [self.view addSubview:self.amountTextField];
    
    
    // Enable Contactless Button
    self.enableContactlessButton = [[UIButton alloc] initWithFrame:CGRectMake((viewFrame.size.width - 200)/2, (viewFrame.size.height + 50)/2, 200, 50)];
    [self.enableContactlessButton setTitle:@"Enable Contactless" forState:UIControlStateNormal];
    [self.enableContactlessButton setBackgroundColor:[UIColor blueColor]];
    [self.enableContactlessButton addTarget:self action:@selector(enableContactlessButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.enableContactlessButton];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Logout" style:UIBarButtonItemStylePlain target:self action:@selector(logout:)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self clearAnyExistingInfo];
    [self setupSimpleInvoice];
    [self updateUIWithActiveReader];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.promptedForSoftwareUpdate = NO;
    [self checkForSoftwareUpgrade];
}

- (void)clearAnyExistingInfo {
    [[PayPalHereSDK sharedTransactionManager] cancelPayment];
    [self.amountTextField setText:@""];
}

- (void)setupSimpleInvoice {
    self.invoice = [[PPHInvoice alloc] init];
    // STEP #1 to take an EMV related payment.
    [[PayPalHereSDK sharedTransactionManager] beginPaymentUsingUIWithInvoice:self.invoice transactionController:self];
}

- (void)enableContactlessButtonPressed:(id)sender {
    // STEP #2 to take an EMV payment.
    // This would activate the reader for a transaction and prompt the user to either tap, insert or swipe their card.
    [[PayPalHereSDK sharedTransactionManager] activateReaderForPayments:NULL];
}

- (void)gotoPaymentCompleteScreenWithResponse:(PPHTransactionResponse *)response {
    PaymentCompleteViewController *paymenCompletetVC = [[PaymentCompleteViewController alloc] initWithTransactionResponse:response];
    [self.navigationController pushViewController:paymenCompletetVC animated:YES];
}

- (void)updateUIWithActiveReader {
    PPHCardReaderMetadata *reader = [PayPalHereSDK sharedCardReaderManager].activeReader;
    NSString *message = @"No Reader Found!";
    UIColor *color = [UIColor blueColor];
    
    if (reader) {
        if (reader.upgradeIsManadatory) {
            message = @"Reader Upgrade Required!";
            color = [UIColor redColor];
        } else {
            message = reader.friendlyName ?: [[PPHReaderConstants stringForReaderType:reader.readerType] stringByAppendingString:@" Reader"];
            message = [message stringByAppendingString:@" Connected!"];
        }
    }
    
    [self.cardReaderStatus setText:message];
    [self.cardReaderStatus setTextColor:color];
    
    
    self.enableContactlessButton.hidden = !(reader.capabilities.paymentCapabilities.contactless &&
                                            [self.invoice.totalAmount isAmountAcceptedForContactless] &&
                                            reader.isReadyToTransact);
}

- (void)logout:(id)sender {
    [[PayPalHereSDK sharedTransactionManager] cancelPayment];
    [PayPalHereSDK clearActiveMerchant];

    LoginViewController *loginVC = ((AppDelegate *)[UIApplication sharedApplication].delegate).loginVC;
    [loginVC forgetTokens];
    [self.navigationController popToViewController:loginVC animated:YES];
}

#pragma mark -
#pragma mark UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView == self.softwareUpgradeAlert && buttonIndex != self.softwareUpgradeAlert.cancelButtonIndex) {
        [self beginReaderUpgrade];
    }
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == self.softwareUpgradeAlert) {
        self.softwareUpgradeAlert = nil;
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string; {
    NSString *amountString = [textField.text stringByReplacingCharactersInRange:range withString:string];

    [self.invoice removeAllItems];

    if (amountString.length) {
        [self.invoice addItemWithId:@"1"
                           detailId:nil
                               name:@"SimpleItem"
                           quantity:[NSDecimalNumber one]
                          unitPrice:[NSDecimalNumber decimalNumberWithString:amountString]
                            taxRate:nil
                        taxRateName:nil];
    }
    
    [self updateUIWithActiveReader];
    
    return YES;
}

#pragma mark -
#pragma PPHTransactionControllerDelegate implementation

-(UINavigationController *)getCurrentNavigationController {
    return self.navigationController;
}

// When the customer either taps, inserts or swipes their card, SDK would call you with this.
// Update your invoice here, if needed, before we proceed with the transaction.
// IMPORTANT NOTE : For a contactless transaction, refrain from updating the invoice once the card is tapped.
- (void)userDidSelectPaymentMethod:(PPHPaymentMethod) paymentOption {
    
    [PayPalHereSDK activeMerchant].invoiceContactInfo.businessName = @"Generic Business";
    
    __weak typeof(self) weakSelf = self;
    // STEP #3 to take an EMV payment. 
    [[PayPalHereSDK sharedTransactionManager] processPaymentUsingUIWithPaymentType:paymentOption
                                                                 completionHandler:^(PPHTransactionResponse *response) {
                                                                     
            if (!response.error) {
                NSLog(@"%@", [NSString stringWithFormat:@" Last Four digits on card : %@, card type: %ld", response.record.invoice.paymentInfo.creditCardLastFourDigits, (long)response.record.invoice.paymentInfo.creditCardType]);
            }
            [weakSelf gotoPaymentCompleteScreenWithResponse:response];
                                                                     
    }];
}

- (void)userDidSelectRefundMethod:(PPHPaymentMethod)refundOption {
}

#pragma mark -
#pragma PPHTransactionManagerDelegate implementation

- (void)onPaymentEvent:(PPHTransactionManagerEvent *)event {
    // Restart the payment if the user cancels it by presing the X button on the reader.
    if (event.eventType == ePPHTransactionType_TransactionCancelled) {
        [[PayPalHereSDK sharedTransactionManager] beginPaymentUsingUIWithInvoice:self.invoice transactionController:self];
    }
}

#pragma mark -
#pragma PPHCardReaderDelegate implementation

- (void)activeReaderChangedFrom:(PPHCardReaderMetadata *)previousReader to:(PPHCardReaderMetadata *)currentReader {
    [self updateUIWithActiveReader];
}

- (void)didDetectReaderDevice:(PPHCardReaderMetadata *)reader {
    [self updateUIWithActiveReader];
    [self checkForSoftwareUpgrade];
}

- (void)didReceiveCardReaderMetadata:(PPHCardReaderMetadata *)metadata {
    [self updateUIWithActiveReader];
    [self checkForSoftwareUpgrade];
}

- (void)didRemoveReader:(PPHReaderType)readerType {
    [self updateUIWithActiveReader];
}

#pragma mark -
#pragma Software Update Related Implementation

- (void)checkForSoftwareUpgrade {
    if (!self.promptedForSoftwareUpdate && [[PayPalHereSDK sharedCardReaderManager].activeReader upgradeIsManadatory]) {
        self.promptedForSoftwareUpdate = YES;
        
        self.softwareUpgradeAlert = [[UIAlertView alloc] initWithTitle:@"Software Upgrade Required"
                                                        message:@"You must update your reader before it is eligible for payment."
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"Start Upgrade", nil];
        [self.softwareUpgradeAlert show];
    }
}

-(void)beginReaderUpgrade {
    __weak typeof(self) weakSelf = self;
    [[PayPalHereSDK sharedCardReaderManager] beginUpgradeUsingSDKUIForReader:[[PayPalHereSDK sharedCardReaderManager] availableReaderOfType:ePPHReaderTypeChipAndPinBluetooth]
                                                           completionHandler:^(BOOL success, NSString *message) {
                                                               weakSelf.promptedForSoftwareUpdate = NO;
                                                               NSString *title = success ? @"Software Upgrade Successful" : @"Software Upgrade Failed";
                                                               UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                                                                               message:nil
                                                                                                              delegate:nil
                                                                                                     cancelButtonTitle:@"OK"
                                                                                                     otherButtonTitles:nil];
                                                               [alert show];
                                                               [[PayPalHereSDK sharedTransactionManager] beginPaymentUsingUIWithInvoice:self.invoice transactionController:weakSelf];
                                                               
    }];
}

#pragma mark -
#pragma mark Receipts

- (NSArray *)getReceiptOptions {
    PPHReceiptOption *receiptOption = [[PPHReceiptOption alloc] initWithBlock:^(PPHTransactionRecord *record, UIView *presentedView) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Transaction Complete"
                                                        message:[NSString stringWithFormat:@"Status: %@", [PPHPaymentConstants stringFromTransactionStatus:record.transactionStatus]]
                                                       delegate:nil cancelButtonTitle:@"Okay..."
                                              otherButtonTitles:nil];
        [alert show];
    } predicate:^BOOL(PPHTransactionRecord *record) {
        return YES;
    } buttonLabel:@"Sample Alert"];
    
    return @[receiptOption];
}
@end
