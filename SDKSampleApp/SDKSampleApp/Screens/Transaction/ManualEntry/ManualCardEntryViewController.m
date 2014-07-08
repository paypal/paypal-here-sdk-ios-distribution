//
//  STViewController.m
//  SDKSampleApp
//
//  Created by Yarlagadda, Harish on 3/10/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//
#import <PayPalHereSDK/PayPalHereSDK.h>
#import "ManualCardEntryViewController.h"
#import "PaymentCompleteViewController.h"
#import "AuthorizationCompleteViewController.h"
#import "STServices.h"
#import "STAppDelegate.h"

@interface ManualCardEntryViewController ()
@property (strong, nonatomic)PPHTransactionResponse *transactionResponse;
@property (nonatomic, retain) IBOutlet UIButton *fillInCardInfoButton;
@property (nonatomic, retain) IBOutlet UIButton *clearCardInfoButton;
@end

@implementation ManualCardEntryViewController

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
    
    self.fillInCardInfoButton.layer.cornerRadius = 10;
    self.clearCardInfoButton.layer.cornerRadius = 10;
    
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];

    NSString *buttonText = appDelegate.paymentFlowIsAuthOnly ? @"Authorize" : @"Process";
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:buttonText
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(onDoneButtonClick:)];
    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)fillInCardInfo:(id)sender
{
    [self.cardNumber setText:@"5428370024365363"];
    [self.expMonth setText:@"02"];
    [self.expYear setText:@"2020"];
    [self.cvv2 setText:@"838"];
}

-(IBAction)clearCardInfo:(id)sender
{
    [self.cardNumber setText:@""];
    [self.expMonth setText:@""];
    [self.expYear setText:@""];
    [self.cvv2 setText:@""];
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
    NSString* cvvStr = [self.cvv2 text];
    
    //preliminary checks for entered info...
    if (nil == cardNumStr || nil == expMonthStr || nil == expYearStr || nil == cvvStr
       || (15 > [cardNumStr length]) || (2 != [expMonthStr length]) || (4 != [expYearStr length])
       || (3 != [cvvStr length]) || (12 < [expMonthStr integerValue]) || ([[self getCurrentYear] integerValue] > [expYearStr integerValue])){
        
        [STServices showAlertWithTitle:@"Error" andMessage:@"Please enter the valid details"];
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
    
    tm.manualEntryOrScannedCardData = manualCardData;
    
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    BOOL authOnly = appDelegate.paymentFlowIsAuthOnly;
    
    if (authOnly) {
        [[PayPalHereSDK sharedTransactionManager] authorizePaymentWithPaymentType:ePPHPaymentMethodKey
                                                            withCompletionHandler:^(PPHTransactionResponse *response) {
                                                                self.transactionResponse = response;
                                                                [self showAuthorizationCompeleteView];
                                                            }];
        
    }
    else {
    
        [tm processPaymentWithPaymentType:ePPHPaymentMethodKey
                withTransactionController:self
                        completionHandler:^(PPHTransactionResponse *record) {
                            self.transactionResponse = record;
                            [self showPaymentCompeleteView];
                        }];
    }

}

-(void) showPaymentCompeleteView
{
    if (_transactionResponse.record != nil) {
        STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
        
        // Add the record into an array so that we can issue a refund later.
        [appDelegate.refundableRecords addObject:_transactionResponse.record];
    }

    PaymentCompleteViewController* paymentCompleteViewController = [[PaymentCompleteViewController alloc]                                                                                         initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:_transactionResponse];
    
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
