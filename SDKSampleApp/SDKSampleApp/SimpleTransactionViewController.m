//
//  SimpleTransactionViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "SimpleTransactionViewController.h"
#import "STChoosePaymentMethodViewController.h"

#import "PayPalHereSDK.h"
@interface SimpleTransactionViewController ()
@property (nonatomic, strong) NSArray *paymentTypesNames;

@end

@implementation SimpleTransactionViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.labelDescription.numberOfLines = 0;
    self.navigationItem.title = @"Simple Transaction";
    self.purchase.layer.cornerRadius = 10;
    
    
    UIToolbar* numberToolbar = [[UIToolbar alloc]init];
    numberToolbar.items = [NSArray arrayWithObjects:
                           [[UIBarButtonItem alloc]initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancelButtonPressed:)],
                           [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                           [[UIBarButtonItem alloc]initWithTitle:@"Purchase!" style:UIBarButtonItemStyleDone target:self action:@selector(purchaseButtonPressed:)],
                           nil];
    [numberToolbar sizeToFit];
    self.price.inputAccessoryView = numberToolbar;

    [self.price setDelegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)cancelButtonPressed:(id)sender {
    [self.price resignFirstResponder];
}

-(IBAction)purchaseButtonPressed:(id)sender {
    // Begin payment to make an invoice.
    STChoosePaymentMethodViewController* vc = [[STChoosePaymentMethodViewController alloc] initWithPurchaseAmount:self.price.text nibName:@"STChoosePaymentMethodViewController" bundle:nil];

    [self.navigationController pushViewController:vc animated:YES];

}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range
replacementString:(NSString *)string
{
    // Update the string in the text input
    NSMutableString* currentString = [NSMutableString stringWithString:textField.text];
    [currentString replaceCharactersInRange:range withString:string];
    // Strip out the decimal separator
    [currentString replaceOccurrencesOfString:@"." withString:@""
                                      options:NSLiteralSearch range:NSMakeRange(0, [currentString length])];
    // Generate a new string for the text input
    int currentValue = [currentString intValue];
    NSString* format = [NSString stringWithFormat:@"%%.%df", 2];
    double minorUnitsPerMajor = 100.0;
    NSString* newString = [NSString stringWithFormat:format, currentValue/minorUnitsPerMajor];
    textField.text = newString;
    return NO;
}

@end
