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
@end

@implementation AddTipViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
           forInvoice:(PPHInvoice *)invoice
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.myInvoice = invoice;
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

-(IBAction)onAddTip:(id)sender
{
    _myInvoice.gratuity = [NSDecimalNumber decimalNumberWithString:_tipToAdd.text];
    [self.navigationController popViewControllerAnimated:YES];
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
    
    
    //Is the string only digts?
    if([self isAllDigits:newValue]) {
        NSDecimalNumber* num = [NSDecimalNumber decimalNumberWithString:newValue];
        NSDecimalNumber *grandTotal = _myInvoice.totalAmount.amount;
        NSDecimalNumber *newSum = [num decimalNumberByAdding: grandTotal];
        self.grandTotalWithTip.text = [newSum description];
        return YES;
    }
    
    return NO;
}

- (BOOL) isAllDigits:(NSString *)string
{
    NSCharacterSet* nonNumbers = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    NSRange r = [string rangeOfCharacterFromSet: nonNumbers];
    return r.location == NSNotFound;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

@end
