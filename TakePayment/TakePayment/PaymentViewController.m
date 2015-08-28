//
//  PaymentViewController.m
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import "PaymentViewController.h"
#import "PaymentCompleteViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface PaymentViewController ()<
    UITextFieldDelegate,
    PPHTransactionControllerDelegate,
    PPHCardReaderDelegate
>

@property(nonatomic, retain) IBOutlet UILabel *cardReaderStatus;
@property(nonatomic, retain) IBOutlet UILabel *enterAmountLabel;
@property(nonatomic, retain) IBOutlet UITextField *amountTextField;
@property(nonatomic, retain) IBOutlet UIButton *enableContactlessButton;
@property (nonatomic, strong) PPHCardReaderWatcher *cardReaderWatcher;
@property (nonatomic, strong) PPHInvoice *invoice;

@end

@implementation PaymentViewController

- (instancetype)init {
    self = [super init];
    if (self) {
        self.cardReaderWatcher = [[PPHCardReaderWatcher alloc] initWithDelegate:self];
        // In case you're using the no hardware version of the SDK, set this to YES. It would suggest that you're using your own swiper hardware and frameworks.
        [[PayPalHereSDK sharedTransactionManager] setIgnoreHardwareReaders:NO];
        // Meant to start monitoring for any available devices.
        [[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self clearAnyExistingInfo];
    [self setupSimpleInvoice];
}

- (void)clearAnyExistingInfo {
    [[PayPalHereSDK sharedTransactionManager] cancelPayment];
    [self.amountTextField setText:@""];
}

- (void)setupView {
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setupEnterAmountLabel];
    [self setupCardReaderStatusLabel];
    [self setupAmountTextField];
    [self setupEnableContactLessButton];
}

- (void)setupSimpleInvoice {
    self.invoice = [[PPHInvoice alloc] init];
    // STEP #1 to take an EMV related payment.
    [[PayPalHereSDK sharedTransactionManager] beginPaymentUsingUIWithInvoice:self.invoice transactionController:self];
}

- (void)setupEnterAmountLabel {
    CGRect viewFrame = self.view.frame;
    self.enterAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake((viewFrame.size.width - 200)/2, (viewFrame.size.height - 150)/2, 200, 50)];
    [self.enterAmountLabel setText:@"Enter an amount"];
    [self.enterAmountLabel setFont:[UIFont systemFontOfSize:15]];
    [self.enterAmountLabel setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.enterAmountLabel];
}

- (void)setupCardReaderStatusLabel {
    CGRect viewFrame = self.view.frame;
    self.cardReaderStatus = [[UILabel alloc] initWithFrame:CGRectMake((viewFrame.size.width - 400)/2, (viewFrame.size.height + 150)/2, 400, 50)];
    [self.cardReaderStatus setFont:[UIFont systemFontOfSize:14]];
    [self.cardReaderStatus setTextAlignment:NSTextAlignmentCenter];
    [self.view addSubview:self.cardReaderStatus];
    
    [self updateReaderStatusWithReader:nil];
}

- (void)setupAmountTextField {
    CGRect viewFrame = self.view.frame;
    self.amountTextField = [[UITextField alloc] initWithFrame:CGRectMake((viewFrame.size.width - 100)/2, (viewFrame.size.height - 50)/2, 100, 40)];
    [self.amountTextField setPlaceholder:@"1.00"];
    [self.amountTextField setTextAlignment:NSTextAlignmentRight];
    [self.amountTextField setBorderStyle:UITextBorderStyleRoundedRect];
    [self.amountTextField setKeyboardType:UIKeyboardTypeDecimalPad];
    self.amountTextField.delegate = self;
    [self.view addSubview:self.amountTextField];
}

- (void)setupEnableContactLessButton {
    CGRect viewFrame = self.view.frame;
    self.enableContactlessButton = [[UIButton alloc] initWithFrame:CGRectMake((viewFrame.size.width - 200)/2, (viewFrame.size.height + 50)/2, 200, 50)];
    [self.enableContactlessButton setTitle:@"Enable Contactless" forState:UIControlStateNormal];
    [self.enableContactlessButton setBackgroundColor:[UIColor blueColor]];
    [self.enableContactlessButton addTarget:self action:@selector(enableContactlessButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.enableContactlessButton];
}

- (IBAction)enableContactlessButtonPressed:(id)sender {
    // STEP #2 to take an EMV payment.
    // This would activate the reader for a transaction and prompt the user to either tap, insert or swipe their card.
    [[PayPalHereSDK sharedTransactionManager] activateReaderForPayments:NULL];
}

- (void)gotoPaymentCompleteScreenWithResponse:(PPHTransactionResponse *)response {
    PaymentCompleteViewController *paymenCompletetVC = [[PaymentCompleteViewController alloc] initWithTransactionResponse:response];
    [self.navigationController pushViewController:paymenCompletetVC animated:YES];
}

- (void)updateReaderStatusWithReader:(PPHCardReaderMetadata *)reader {
    if (reader) {
        NSString *readerName = reader.friendlyName ?: [[PPHReaderConstants stringForReaderType:reader.readerType] stringByAppendingString:@" Reader"];
        [self.cardReaderStatus setText:[NSString stringWithFormat:@"%@ Connected!", readerName]];
        [self.cardReaderStatus setTextColor:[UIColor blueColor]];
    } else {
        [self.cardReaderStatus setText:@"No Reader Found!"];
        [self.cardReaderStatus setTextColor:[UIColor redColor]];
    }
}


#pragma mark -
#pragma mark UITextFieldDelegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string; {
    NSString *amountString = [textField.text stringByReplacingCharactersInRange:range withString:string];
   
    [self.invoice removeAllItems];
    [self.invoice addItemWithId:@"1"
                       detailId:nil
                           name:@"SimpleItem"
                       quantity:[NSDecimalNumber one]
                      unitPrice:[NSDecimalNumber decimalNumberWithString:amountString]
                        taxRate:nil
                    taxRateName:nil];
    
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

    __weak typeof(self) weakSelf = self;
    // STEP #3 to take an EMV payment. 
    [[PayPalHereSDK sharedTransactionManager] processPaymentUsingUIWithPaymentType:paymentOption
                                                                 completionHandler:^(PPHTransactionResponse *response) {
                                                                     
                                                                     [weakSelf gotoPaymentCompleteScreenWithResponse:response];
                                                                     
    }];
}

- (void)displayReaderStatusWithMessage:(NSString *)message successfulStatus:(BOOL) status {
    [self.cardReaderStatus setText:message];
    if (status) {
        [self.cardReaderStatus setTextColor:[UIColor blueColor]];
    } else {
        [self.cardReaderStatus setTextColor:[UIColor redColor]];
    }
}

#pragma mark -
#pragma PPHCardReaderDelegate implementation

- (void)didDetectReaderDevice:(PPHCardReaderMetadata *)reader {
    [self updateReaderStatusWithReader:reader];
    [self checkForSoftwareUpgrade];
}

- (void)didRemoveReader:(PPHReaderType)readerType {
    [self updateReaderStatusWithReader:[PayPalHereSDK sharedCardReaderManager].activeReader];
}

#pragma mark -
#pragma Software Update Related Implementation

- (void)checkForSoftwareUpgrade {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if ([self updateRequired]) {
            [self beginReaderUpdate];
        } else {
            [self displayReaderStatusWithMessage:@"Ready To Transact" successfulStatus:YES];
        }
    });
}

-(void)beginReaderUpdate {
    __weak typeof(self) weakSelf = self;
    [[PayPalHereSDK sharedCardReaderManager] beginUpgradeUsingSDKUIForReader:[[PayPalHereSDK sharedCardReaderManager] availableReaderOfType:ePPHReaderTypeChipAndPinBluetooth]
                                                           completionHandler:^(BOOL success, NSString *message) {
                                                               
        [weakSelf softwareUpdateCompleteWithStatus:success andMessage:message];
    }];
}

-(void)softwareUpdateCompleteWithStatus:(BOOL)success andMessage:(NSString *)message {
    if (success) {
        [self displayReaderStatusWithMessage:@"Ready To Transact" successfulStatus:YES];
    } else {
        [self displayReaderStatusWithMessage:@"Update Failed" successfulStatus:NO];
    }
    
}

-(BOOL)updateRequired {
    return [[PayPalHereSDK sharedCardReaderManager].activeReader upgradeIsManadatory];
}

@end
