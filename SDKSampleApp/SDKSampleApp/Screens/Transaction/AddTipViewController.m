//
//  AddTipViewController.m
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/26/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "AddTipViewController.h"

#import <PayPalHereSDK/PPHInvoice.h>
#import <PayPalHereSDK/PPHAmount.h>

@interface AddTipViewController ()
@property (strong, nonatomic) PPHInvoice *myInvoice;
@property (strong, nonatomic) NSDecimalNumberHandler *formatter;
@end

@implementation AddTipViewController

/*
 * When creating the AddTipViewController an invoice will be passed in.  This
 * class will attempt to collect a tip amount from the customer and add it to 
 * this invoice.
 */
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
           forInvoice:(PPHInvoice *)invoice
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.myInvoice = invoice;
        self.formatter = [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundDown
                                                                                scale:2
                                                                     raiseOnExactness:NO
                                                                      raiseOnOverflow:NO
                                                                     raiseOnUnderflow:NO
                                                                  raiseOnDivideByZero:NO];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    NSDecimalNumber *total = _myInvoice.subTotal;
    NSDecimalNumber *tip = _myInvoice.gratuity;
    NSDecimalNumber *grandTotal = _myInvoice.totalAmount.amount;

    self.purchaseTotal.text = [total description];
    self.tipToAdd.text = [tip description];
    self.grandTotalWithTip.text = [grandTotal description];
    
    [_tipToAdd resignFirstResponder];
}

-(IBAction)onCancel:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

/*
 * Called when the user taps the Add Tip button.
 *
 * Here we update the invoice's gratuity field.
 */
-(IBAction)onAddTip:(id)sender
{
    NSDecimalNumber *formattedTip = [self formatNumber:_tipToAdd.text];
    
    _myInvoice.gratuity = formattedTip;
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSDecimalNumber *)formatNumber:(NSString *)value
{
    NSDecimalNumber *nsdnValue = [NSDecimalNumber decimalNumberWithString:value];
    return [nsdnValue decimalNumberByRoundingAccordingToBehavior:_formatter];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *newValue = nil;
    if(range.location == [textField.text length] && [string length] == 1) {
        newValue = [NSString stringWithFormat:@"%@%@", textField.text, string];
    }
    else if(range.location == [textField.text length] - 1 && [string length] == 0) {
        NSRange desiredRange = { 0, [textField.text length] - 1 };
        newValue = [textField.text substringWithRange:desiredRange];
    }
    
    if([newValue length] <= 0) {
        self.grandTotalWithTip.text = [_myInvoice.totalAmount.amount description];
        return YES;
    }
    
    NSDecimalNumber *num = [self formatNumber:newValue];
    NSString *newStr = [num description];
    int desiredLen = [newStr length];
    int currentLen = [_tipToAdd.text length];
    if(![self isPeriod:string] && desiredLen == currentLen) {
        return NO;
    }
    
    NSDecimalNumber *grandTotal = _myInvoice.totalAmount.amount;
    NSDecimalNumber *newSum = [num decimalNumberByAdding: grandTotal];
    
    self.grandTotalWithTip.text = [newSum description];
    return YES;
}

- (BOOL) isPeriod:(NSString*) string {
    return [string length] == 1 && [string compare:@"."] == NSOrderedSame;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
