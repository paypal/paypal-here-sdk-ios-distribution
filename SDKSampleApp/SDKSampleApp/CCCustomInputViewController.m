//
//  CCCustomInputViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/23/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "CCCustomInputViewController.h"
#import "STAppDelegate.h"

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
    tm.manualEntryOrScannedCardData = manualData;
    if (!manualData) {
        return;
    }
    [tm processPaymentWithPaymentType:ePPHPaymentMethodKey withTransactionController:self completionHandler:^(PPHTransactionResponse *response){
        
    }];
}

-(PPHTransactionControlActionType)onPreAuthorizeForInvoice:(PPHInvoice *)inv withPreAuthJSON:(NSMutableDictionary*) preAuthJSON {
    NSURL *url = [NSURL URLWithString:STAGE];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSData *jsonData =  [NSJSONSerialization dataWithJSONObject:preAuthJSON
                                                        options:NSJSONWritingPrettyPrinted
                                                          error:nil];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:jsonData];
    [request setValue:@"Content-type" forHTTPHeaderField:@"Content-type"];
    //[request setValue: forHTTPHeaderField:@"Authorization"];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
    
    }];
    
    return ePPHTransactionType_Handled;
}

-(void)onPostAuthorize:(BOOL)didFail {
    
}

- (void)onPaymentEvent:(PPHTransactionManagerEvent *) event {
    
}

@end
