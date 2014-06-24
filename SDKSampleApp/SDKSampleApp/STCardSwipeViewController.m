//
//  STCardSwipeViewController.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/18/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import "STCardSwipeViewController.h"
#import "PaymentCompleteViewController.h"
#import "SignatureViewController.h"
#import <PayPalHereSDK/PPHTransactionWatcher.h>

@interface STCardSwipeViewController ()
@property (nonatomic, retain) IBOutlet UIImageView *swipeImageView;
@property (nonatomic, strong) NSString *amount;
@property (nonatomic, strong) PPHTransactionWatcher *transactionWatcher;
@property BOOL waitingForCardSwipe; // Used to only accept first valid swipe.
@end

@implementation STCardSwipeViewController

- (id)initWithAmount:(NSString *)amount nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.transactionWatcher = [[PPHTransactionWatcher alloc] initWithDelegate:self];
        self.amount = amount;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Beginning the transaction allows the swiper to listen for swipes. 
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHAmount *total = [PPHAmount amountWithString:self.amount inCurrency:@"USD"];
    tm.ignoreHardwareReaders = NO;
    [tm beginPaymentWithAmount:total andName:@"simplePayment"];
    
    self.swipeImageView.layer.cornerRadius = 10;
    self.waitingForCardSwipe = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)collectSignatureAndFinalizePurchaseWithRecord: (PPHTransactionResponse *)response
{
    NSString *interfaceName = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) ? @"SignatureViewController_iPhone" : @"SignatureViewController_iPad";
    SignatureViewController *settings =  [[SignatureViewController alloc] initWithNibName:interfaceName bundle:nil transactionResponse:response];
    [self.navigationController pushViewController:settings animated:YES];
}

/*
 * Called when the transaction manager wants to communicate certain events.
 */
-(void)onPaymentEvent:(PPHTransactionManagerEvent *) event
{
    if (event.eventType == ePPHTransactionType_CardDataReceived && self.waitingForCardSwipe)  {
          self.waitingForCardSwipe = NO;
        
        UIActivityIndicatorView *spinny = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [spinny setFrame:CGRectMake(0, 0, 100, 100)];
        [spinny startAnimating];
        UIBarButtonItem *loading = [[UIBarButtonItem alloc] initWithCustomView:spinny];
        self.navigationItem.rightBarButtonItem = loading;

        [[PayPalHereSDK sharedTransactionManager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe
                                                      withTransactionController:nil
                                                              completionHandler:^(PPHTransactionResponse *response) {
                                                                  if (response.error || !response.isSignatureRequiredToFinalize) {
                                                                      PaymentCompleteViewController *paymentCompleteViewController = [[PaymentCompleteViewController alloc] initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:response];
                                                                      
                                                                      [self.navigationController pushViewController:paymentCompleteViewController animated:YES];
                                                                  } else {
                                                                      // Is a signature required for this payment?  If so
                                                                      // then let's collect a signature and provide it to the SDK.
                                                                     [self collectSignatureAndFinalizePurchaseWithRecord:response];
                                                                  }
                                                              }];
    }
}


@end
