//
//  PaymentCompleteViewController.m
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import "PaymentCompleteViewController.h"


@interface PaymentCompleteViewController ()<PPHTransactionControllerDelegate>

@property (nonatomic, retain) IBOutlet UILabel *transactionStatus;
@property (nonatomic, retain) IBOutlet UIButton *refundButton;
@property (nonatomic, retain) IBOutlet UIButton *doneButton;

@property (nonatomic, strong) PPHTransactionResponse *transactionResponse;
@property (nonatomic, assign) BOOL transactionFailed;

@end

@implementation PaymentCompleteViewController

- (instancetype)initWithTransactionResponse:(PPHTransactionResponse *)transactionResponse {

    self = [super init];
    if (self) {
        self.transactionResponse = transactionResponse;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

- (void)setupView {
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self.navigationItem setHidesBackButton:YES];
    [self setupTransactionStatusLabel];
    [self setupRefundButton];
    [self setupDoneButton];
}

- (void)setupTransactionStatusLabel {
    CGRect viewFrame = self.view.frame;
    self.transactionStatus = [[UILabel alloc] initWithFrame:CGRectMake(0, 100, viewFrame.size.width, 50)];
    [self.transactionStatus setFont:[UIFont systemFontOfSize:20]];
    [self.transactionStatus setTextAlignment:NSTextAlignmentCenter];
    if (self.transactionResponse.error) {
        [self.transactionStatus setText:@"Payment Failed"];
        [self.transactionStatus setTextColor:[UIColor redColor]];
        self.transactionFailed = YES;
    } else {
        [self.transactionStatus setText:@"Payment Successful"];
        [self.transactionStatus setTextColor:[UIColor blueColor]];
        self.transactionFailed = NO;
    }
    [self.view addSubview:self.transactionStatus];
}

- (void)setupRefundButton {
    CGRect viewFrame = self.view.frame;
    self.refundButton = [[UIButton alloc] initWithFrame:CGRectMake(0, (viewFrame.size.height - 60)/2, viewFrame.size.width , 50)];
    [self.refundButton setTitle:@"Refund" forState:UIControlStateNormal];
    [self.refundButton setBackgroundColor:[UIColor orangeColor]];
    [self.refundButton addTarget:self action:@selector(refundButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    if (self.transactionFailed) {
        [self.refundButton setEnabled:NO];
        [self.refundButton setAlpha:0.3f];
    }
    [self.view addSubview:self.refundButton];
    
}

- (void)setupDoneButton {
    CGRect viewFrame = self.view.frame;
    self.doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, (viewFrame.size.height + 60)/2, viewFrame.size.width, 50)];
    [self.doneButton setTitle:@"Done" forState:UIControlStateNormal];
    [self.doneButton setBackgroundColor:[UIColor blueColor]];
    [self.doneButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.doneButton];
}

- (void)refundButtonPressed {
    // STEP #1 to perform a refund.
    [[PayPalHereSDK sharedTransactionManager] beginRefundUsingUIWithInvoice:self.transactionResponse.record.invoice
                                                      transactionController:self];
}

- (void)doneButtonPressed {
    // Once the transaction (and/or refund) is complete, pop to your root view controller.
    [self.navigationController popToRootViewControllerAnimated:YES];
}

#pragma mark -
#pragma PPHTransactionControllerDelegate implementation

-(UINavigationController *)getCurrentNavigationController {
    return self.navigationController;
}

- (void)userDidSelectPaymentMethod:(PPHPaymentMethod)paymentOption {
}

- (void)userDidSelectRefundMethod:(PPHPaymentMethod)refundOption {
    __weak typeof(self) weakSelf = self;
    // STEP #2 to perform a refund.
    [[PayPalHereSDK sharedTransactionManager] processRefundUsingUIWithAmount:self.transactionResponse.record.invoice.totalAmount
                                                           completionHandler:^(PPHTransactionResponse *response) {
                                                               
                                                               [weakSelf doneButtonPressed];

    }];
    
}


@end
