//
//  SimpleTransactionViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "SimpleTransactionViewController.h"
#import "STPaymentMethodViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>
@interface SimpleTransactionViewController ()
@property (nonatomic, strong) NSArray *paymentTypesNames;

@end

@implementation SimpleTransactionViewController


- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.description.numberOfLines = 0;
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
    STPaymentMethodViewController* vc = [[STPaymentMethodViewController alloc] initWithPurchaseAmount:self.price.text nibName:@"STPaymentMethodViewController" bundle:nil];

    [self.navigationController pushViewController:vc animated:YES];

}

@end
