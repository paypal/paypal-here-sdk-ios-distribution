//
//  CCCustomInputViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/23/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "CCCustomInputViewController.h"
#import "PaymentCompleteViewController.h"
#import "STAppDelegate.h"
#import "STServices.h"

@interface CCCustomInputViewController ()
@property (retain, nonatomic) IBOutlet UIButton *fillInCardInfo;
@property (retain, nonatomic) IBOutlet UIButton *clearCardInfo;

@property (weak, nonatomic) IBOutlet UITextField *cardNumber;
@property (weak, nonatomic) IBOutlet UITextField *expMonth;
@property (weak, nonatomic) IBOutlet UITextField *expYear;
@property (weak, nonatomic) IBOutlet UITextField *cvv2;

-(IBAction)fillInCardInfo:(id)sender;
-(IBAction)clearCardInfo:(id)sender;
-(IBAction)didPressProcess:(id)sender;
@end

@implementation CCCustomInputViewController

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
    
    self.fillInCardInfo.layer.cornerRadius = 10;
    self.clearCardInfo.layer.cornerRadius = 10;
    
    UIBarButtonItem *rightButton = [[UIBarButtonItem alloc] initWithTitle:@"Process!"
                                                                    style:UIBarButtonItemStyleDone target:self action:@selector(didPressProcess:)];
    self.navigationItem.rightBarButtonItem = rightButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)fillInCardInfo:(id)sender {
    [self.cardNumber setText:@"4111111111111111"];
    [self.expMonth setText:@"09"];
    [self.expYear setText:@"2019"];
    [self.cvv2 setText:@"408"];
}

-(IBAction)clearCardInfo:(id)sender {
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


-(IBAction)didPressProcess:(id)sender {
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHCardNotPresentData *manualData = [self extractCardDataFromTextFields];
    if (!manualData) {
        [STServices showAlertWithTitle:@"Error!" andMessage:@"Card data invalid"];
        return;
    }
    tm.manualEntryOrScannedCardData = manualData;
    [tm processPaymentWithPaymentType:ePPHPaymentMethodKey withTransactionController:self completionHandler:^(PPHTransactionResponse *response){
        
    }];
}

-(PPHTransactionControlActionType)onPreAuthorizeForInvoice:(PPHInvoice *)inv withPreAuthJSON:(NSMutableDictionary*) preAuthJSON {
    
    UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [spinny setFrame:CGRectMake(0, 0, 100, 100)];
    [spinny startAnimating];
    UIBarButtonItem *loading = [[UIBarButtonItem alloc] initWithCustomView:spinny];
    self.navigationItem.rightBarButtonItem = loading;

    
    NSURL *url = [NSURL URLWithString:@"https://www.stage2mb006.stage.paypal.com/webapps/hereapi/merchant/v1/pay"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSData *jsonData =  [NSJSONSerialization dataWithJSONObject:preAuthJSON
                                                        options:0
                                                          error:nil];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", [PayPalHereSDK activeMerchant].payPalAccount.access_token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json; charset=UTF-8" forHTTPHeaderField:@"Content-Type"];


    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        PPHTransactionResponse *transactionResponse = [[PPHTransactionResponse alloc] init];
        if (error) {
            transactionResponse.error = [PPHError pphErrorWithNSError:error];
        } else {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            transactionResponse.record = [[PPHTransactionRecord alloc] initWithTransactionId:dict[@"transactionNumber"] andWithPayPalInvoiceId:dict[@"invoiceId"]];
        }
        PaymentCompleteViewController *vc = [[PaymentCompleteViewController alloc] initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:transactionResponse];
        [self.navigationController pushViewController:vc animated:YES];
    }];
    
    return ePPHTransactionType_Handled;
}

-(void)onPostAuthorize:(BOOL)didFail {
    
}

- (void)onPaymentEvent:(PPHTransactionManagerEvent *) event {
    
}

@end
