//
//  STPaymentMethodViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/17/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//
#import "STAppDelegate.h"

#import "STChoosePaymentMethodViewController.h"
#import "STCashPaymentViewController.h"
#import "STManualPaymentViewController.h"
#import "STCardSwipeViewController.h"
#import "CheckedInCustomerViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>
@interface STChoosePaymentMethodViewController ()
@property (nonatomic, retain) IBOutlet UILabel *amountLabel;
@property (nonatomic, retain) IBOutlet UIButton *manualButton;
@property (nonatomic, retain) IBOutlet UIButton *checkinButton;
@property (nonatomic, retain) IBOutlet UIButton *cashButton;
@property (nonatomic, retain) IBOutlet UIButton *swipeButton;
@property (nonatomic, strong) NSString *amount;
@property BOOL waitingForCardSwipe;
@end

@implementation STChoosePaymentMethodViewController


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
    self.amountLabel.text = self.amount;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)didPressSwipe:(id)sender {
    STCardSwipeViewController *vc = [[STCardSwipeViewController alloc] initWithAmount:self.amount nibName:@"STCardSwipeViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

-(IBAction)didPressManual:(id)sender {
    STManualPaymentViewController *cardEntryView = [[STManualPaymentViewController alloc] initWithAmount:self.amount nibName:@"STManualPaymentViewController" bundle:nil];

    [self.navigationController pushViewController:cardEntryView animated:YES];
}

-(IBAction)didPressCash:(id)sender {
    STCashPaymentViewController *vc = [[STCashPaymentViewController alloc] initWithAmount:self.amount nibName:@"STCashPaymentViewController" bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

-(IBAction)didPressCheckIn:(id)sender {
    STAppDelegate *appDelegate = (STAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.isMerchantCheckedin){
        UIAlertView *alert = [ [UIAlertView alloc] initWithTitle:@"Alert"
                                                         message:@"You are not checked-in. Please go to Settings and check-in first to take payments through this channel"
                                                        delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil ];
        [alert show];
        return;
    }
    
    NSString *interfaceName = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"CheckedInCustomerViewController_iPhone" : @"CheckedInCustomerViewController_iPad";
    [[PayPalHereSDK sharedTransactionManager] beginPaymentWithAmount:[PPHAmount amountWithString:self.amount inCurrency:@"USD"] andName:@"FixedAmount"];
    
    CheckedInCustomerViewController *vc = [[CheckedInCustomerViewController alloc] initWithNibName:interfaceName bundle:nil];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
