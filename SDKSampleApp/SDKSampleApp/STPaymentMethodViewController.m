//
//  STPaymentMethodViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "STPaymentMethodViewController.h"
#import "STCashPaymentViewController.h"
#import "ManualCardEntryViewController.h"
#import "PaymentCompleteViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>
@interface STPaymentMethodViewController ()

@property (nonatomic, retain) IBOutlet UIButton *manualButton;
@property (nonatomic, retain) IBOutlet UIButton *checkinButton;
@property (nonatomic, retain) IBOutlet UIButton *cashButton;
@property (nonatomic, retain) IBOutlet UIButton *swipeButton;
@property (nonatomic, strong) NSString *amount;
@property BOOL waitingForCardSwipe;
@end

@implementation STPaymentMethodViewController


- (id)initWithPurchaseAmount:(NSString *)amount nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
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
    self.manualButton.layer.cornerRadius = 10;
    self.checkinButton.layer.cornerRadius = 10;
    self.cashButton.layer.cornerRadius = 10;
    self.swipeButton.layer.cornerRadius = 10;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)didPressSwipe:(id)sender {
    UIView *view = [[UIView alloc]initWithFrame:self.view.frame];
    view.backgroundColor = [[UIColor alloc] initWithRed:190 green:190 blue:190 alpha:.8];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(100, 200, 200, 200)];
    label.text = @"Swipe card now";
    
    [view addSubview:label];
    
    [self.view addSubview:view];
    

}

-(IBAction)didPressManual:(id)sender {
    ManualCardEntryViewController *cardEntryView = [[ManualCardEntryViewController alloc]
                                                    initWithNibName:@"ManualCardEntryViewController"
                                                    bundle:nil];
    [self.navigationController pushViewController:cardEntryView animated:YES];
}

-(IBAction)didPressCash:(id)sender {
    STCashPaymentViewController *vc = [[STCashPaymentViewController alloc] initWithAmount:self.amount nibName:@"STCashPaymentViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
    //For Cash the PPHTransactionManager will simply record the invoice to the backend.
    
//    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
//    PPHAmount *total = [PPHAmount amountWithString:self.amount inCurrency:@"USD"];
//    [tm beginPaymentWithAmount:total andName:@"simplePayment"];
//
//    [tm processPaymentWithPaymentType:ePPHPaymentMethodCash
//            withTransactionController:nil
//                    completionHandler:^(PPHTransactionResponse *record) {
//                        PaymentCompleteViewController *paymentCompleteViewController = [[PaymentCompleteViewController alloc] initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:record];
//                        
//                        [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
//                    }];

}

-(IBAction)didPressCheckIn:(id)sender {
    
}

@end
