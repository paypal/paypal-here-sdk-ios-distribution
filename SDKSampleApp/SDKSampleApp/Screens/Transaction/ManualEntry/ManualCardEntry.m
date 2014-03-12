//
//  STViewController.m
//  SDKSampleApp
//
//  Created by Yarlagadda, Harish on 3/10/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//
#import <PayPalHereSDK/PayPalHereSDK.h>
#import "ManualCardEntry.h"
#import "PaymentCompleteViewController.h"

@interface ManualCardEntry ()
@property (assign, nonatomic)BOOL doneWithPayScreen;
@property (strong, nonatomic)PPHTransactionResponse *transactionResposne;
@end

@implementation ManualCardEntry

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.processingTransactionSpinny.hidden=YES;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(onDoneButtonClick:)];
    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(NSString*) getCurrentYear
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];
    return yearString;
}

- (void) onDoneButtonClick:(id)sender
{
    NSString* cardNumStr = [self.cardNumber text];
    NSString* expMonthStr = [self.expMonth text];
    NSString* expYearStr = [self.expYear text];
    NSString* cvvStr = [self.cvv text];
    
    if(nil == cardNumStr || nil == expMonthStr || nil == expYearStr || nil == cvvStr
       || (15 > [cardNumStr length]) || (2 != [expMonthStr length]) || (4 != [expYearStr length])
       || (3 != [cvvStr length]) || (12 < [expMonthStr integerValue]) || ([[self getCurrentYear] integerValue] > [expYearStr integerValue])){
        
        [self showAlertWithTitle:@"Error" andMessage:@"Please enter the valid details"];
        return;
    }
    
    self.processingTransactionSpinny.hidden=NO;
    [self.processingTransactionSpinny startAnimating];
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:[expMonthStr integerValue]];
    [comps setYear:[expYearStr integerValue]];
    
    PPHCardNotPresentData *manualCardData = [[PPHCardNotPresentData alloc] init];
    manualCardData.cardNumber = cardNumStr;
    manualCardData.cvv2 = cvvStr;
    manualCardData.expirationDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    //Now, take a payment with it
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    
    //[tm beginPaymentWithAmount:[PPHAmount amountWithString:@"33.00" inCurrency:@"USD"] andName:@"FixedAmountPayment"];
    tm.manualEntryOrScannedCardData = manualCardData;
    
    
    [tm processPaymentWithPaymentType:ePPHPaymentMethodKey
            withTransactionController:self
                    completionHandler:^(PPHTransactionResponse *record) {
                        self.transactionResposne = record;
                        [self showPaymentCompeleteView];
                    }];

}

-(void) showPaymentCompeleteView
{
    PaymentCompleteViewController* paymentCompleteViewController = [[PaymentCompleteViewController alloc]                                                                                         initWithNibName:@"PaymentCompleteViewController" bundle:nil];
    paymentCompleteViewController.transactionResponse = _transactionResposne;
    [self.navigationController pushViewController:paymentCompleteViewController animated:YES]; 
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

@end
