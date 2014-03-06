//
//  PaymentCompleteViewController.m
//  SDKSampleApp
//
//  Created by Chandrashekar,Sathyanarayan on 3/5/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "PaymentCompleteViewController.h"
#import "ReceiptInfoViewController.h"

@interface PaymentCompleteViewController ()

@end

@implementation PaymentCompleteViewController

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
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)onEmailPressed:(id)sender
{
    [self showReceiptView:YES];
}

-(IBAction)onTextPressed:(id)sender
{
    [self showReceiptView:NO];
}

-(IBAction)onNoThanksPressed:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void) showReceiptView:(BOOL *)isEmail
{
    ReceiptInfoViewController* receiptInfoViewController = [[ReceiptInfoViewController alloc]
                                                                    initWithNibName:@"ReceiptInfoViewController"
                                                                    bundle:nil];
    receiptInfoViewController.isEmail = isEmail;
    receiptInfoViewController.transactionRecord = _transactionRecord;
    [self.navigationController pushViewController:receiptInfoViewController animated:YES];
}

@end
