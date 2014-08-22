//
//  STManualPaymentViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/18/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "STManualPaymentViewController.h"
#import "PaymentCompleteViewController.h"
#import "STServices.h"

#import <PayPalHereSDK/PayPalHereSDK.h>

@interface STManualPaymentViewController ()
@property (nonatomic, strong) NSString *amount;


@property (retain, nonatomic) IBOutlet UIButton *fillInCardInfo;
@property (retain, nonatomic) IBOutlet UIButton *clearCardInfo;

@property (weak, nonatomic) IBOutlet UITextField *cardNumber;
@property (weak, nonatomic) IBOutlet UITextField *expMonth;
@property (weak, nonatomic) IBOutlet UITextField *expYear;
@property (weak, nonatomic) IBOutlet UITextField *cvv2;

-(IBAction)fillInCardInfo:(id)sender;
-(IBAction)clearCardInfo:(id)sender;
@end

@implementation STManualPaymentViewController

- (id)initWithAmount: (NSString *) amount nibName: (NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.amount = amount;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.fillInCardInfo.layer.cornerRadius = 10;
    self.clearCardInfo.layer.cornerRadius = 10;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Process!"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(carryOutPayment:)];
    self.navigationItem.rightBarButtonItem = rightButton;
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]init];
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed:)],
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Purchase!" style:UIBarButtonItemStyleDone target:self action:@selector(purchaseButtonPressed:)],
                           nil];
    [numberToolbar sizeToFit];
    self.cardNumber.inputAccessoryView = numberToolbar;
    self.expMonth.inputAccessoryView = numberToolbar;
    self.expYear.inputAccessoryView = numberToolbar;
    self.cvv2.inputAccessoryView = numberToolbar;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)fillInCardInfo:(id)sender {
    [self.cardNumber setText:@"5428370024365363"];
    [self.expMonth setText:@"02"];
    [self.expYear setText:@"2020"];
    [self.cvv2 setText:@"838"];
}

-(IBAction)clearCardInfo:(id)sender {
    [self.cardNumber setText:@""];
    [self.expMonth setText:@""];
    [self.expYear setText:@""];
    [self.cvv2 setText:@""];
}
-(void)cancelButtonPressed:(id)sender {
    [self.cardNumber resignFirstResponder];
    [self.expMonth resignFirstResponder];
    [self.expYear resignFirstResponder];
    [self.cvv2 resignFirstResponder];

}

-(void)purchaseButtonPressed:(id) sender {
    [self.cardNumber resignFirstResponder];
    [self.expMonth resignFirstResponder];
    [self.expYear resignFirstResponder];
    [self.cvv2 resignFirstResponder];
    
    [self carryOutPayment:sender];
}

-(NSString*) getCurrentYear
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy"];
    NSString *yearString = [formatter stringFromDate:[NSDate date]];
    return yearString;
}

-(PPHCardNotPresentData *)extractCardDataFromTextFields {
    // Extract Card Data from fields
    NSString* cardNumStr = [self.cardNumber text];
    NSString* expMonthStr = [self.expMonth text];
    NSString* expYearStr = [self.expYear text];
    NSString* cvvStr = [self.cvv2 text];
    
    //preliminary checks for entered info...
    if (nil == cardNumStr || nil == expMonthStr || nil == expYearStr || nil == cvvStr
        || (15 > [cardNumStr length]) || (2 != [expMonthStr length]) || (4 != [expYearStr length])
        || (3 != [cvvStr length]) || (12 < [expMonthStr integerValue]) || ([[self getCurrentYear] integerValue] > [expYearStr integerValue])){
        return nil;
    }
    
    
    NSDateComponents *comps = [[NSDateComponents alloc] init];
    [comps setMonth:[expMonthStr integerValue]];
    [comps setYear:[expYearStr integerValue]];
    
    PPHCardNotPresentData *manualCardData = [[PPHCardNotPresentData alloc] init];
    manualCardData.cardNumber = cardNumStr;
    manualCardData.cvv2 = cvvStr;
    manualCardData.expirationDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
    
    return manualCardData;
}

- (IBAction)carryOutPayment:(id)sender
{
    PPHCardNotPresentData *manualCardData = [self extractCardDataFromTextFields];
    if (!manualCardData) {
        [STServices showAlertWithTitle:@"Error" andMessage:@"Please enter the valid details"];
        return;
    }
    
    //Now, make a payment with card data
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHAmount *total = [PPHAmount amountWithString:self.amount inCurrency:@"USD"];
    [tm beginPaymentWithAmount:total andName:@"simplePayment"];
    tm.manualEntryOrScannedCardData = manualCardData;
    
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinny setFrame:CGRectMake(0, 0, 100, 100)];
    [spinny startAnimating];
    UIBarButtonItem *loading = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    self.navigationItem.rightBarButtonItem = loading;
    
    [self.fillInCardInfo setEnabled:NO];
    [self.clearCardInfo setEnabled:NO];
    [self.cvv2 setEnabled:NO];
    [self.expYear setEnabled:NO];
    [self.expMonth setEnabled:NO];
    [self.cardNumber setEnabled:NO];
    
    [tm processPaymentWithPaymentType:ePPHPaymentMethodKey
                withTransactionController:nil
                        completionHandler:^(PPHTransactionResponse *record) {
                            PaymentCompleteViewController* paymentCompleteViewController = [[PaymentCompleteViewController alloc]                                                                                         initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:record];
                            [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
                            }
     ];
}


@end
