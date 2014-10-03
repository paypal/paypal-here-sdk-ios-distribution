//
//  STCashPaymentViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "STCashPaymentViewController.h"
#import "PaymentCompleteViewController.h"

@interface STCashPaymentViewController ()
@property (nonatomic, strong) NSString *amount;
@property (nonatomic, retain) IBOutlet UIButton *doneButton;
@end

@implementation STCashPaymentViewController

- (id)initWithAmount: (NSString *)amount nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
    self.doneButton.layer.cornerRadius = 10;
    _activity.hidden = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)doneButtonPressed:(id)sender{
    [sender setEnabled:NO];
    
    _activity.hidden = NO;
    [_activity startAnimating];
    
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHAmount *total = [PPHAmount amountWithString:self.amount inCurrency:@"USD"];
    [tm beginPaymentWithAmount:total andName:@"simplePayment"];
    
    [tm processPaymentWithPaymentType:ePPHPaymentMethodCash
            withTransactionController:nil
                    completionHandler:^(PPHTransactionResponse *record) {
                        // finished processing
                        _activity.hidden = YES;
                        [_activity stopAnimating];

                        PaymentCompleteViewController *paymentCompleteViewController = [[PaymentCompleteViewController alloc] initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:record];
                        
                        [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
                    }];
}



@end
