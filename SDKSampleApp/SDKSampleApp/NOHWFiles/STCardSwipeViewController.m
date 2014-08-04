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
#import "NoHWCardReaderManager.h"

#import <PayPalHereSDK/PPHCardSwipeData.h>
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface STCardSwipeViewController ()
@property (nonatomic, retain) IBOutlet UIImageView *swipeImageView;
@property (nonatomic, retain) IBOutlet UILabel *deviceStatus;
@property (nonatomic, strong) NSString *amount;
@property (nonatomic, strong) PPHCardSwipeData *data;
@end

@implementation STCardSwipeViewController

- (id)initWithAmount:(NSString *)amount nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
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
    
    // Beginning the transaction allows the swiper to listen for swipes. 
    PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
    PPHAmount *total = [PPHAmount amountWithString:self.amount inCurrency:@"USD"];
    [tm beginPaymentWithAmount:total andName:@"simplePayment"];
    
    self.swipeImageView.layer.cornerRadius = 10;
    self.swipeImageView.layer.masksToBounds = YES;
    
    void (^dataReadyBlock)(PPHCardSwipeData *) = ^(PPHCardSwipeData *swipeData){
        // Set Card Data
        PPHTransactionManager *tm = [PayPalHereSDK sharedTransactionManager];
        tm.encryptedCardData = swipeData;
        
        // Process Transaction
        [tm processPaymentWithPaymentType:ePPHPaymentMethodSwipe withTransactionController:nil completionHandler:^(PPHTransactionResponse *response){
            if (!response.error || !response.isSignatureRequiredToFinalize) {
                PaymentCompleteViewController *vc = [[PaymentCompleteViewController alloc] initWithNibName:@"PaymentCompleteViewController" bundle:nil forResponse:response];
                [self.navigationController pushViewController:vc animated:YES];
            }
            else {
                NSString *nibName = (IS_IPHONE) ? @"SignatureViewController_iPhone" : @"SignatureViewController_iPad";
                [self.navigationController pushViewController:[[SignatureViewController alloc] initWithNibName:nibName bundle:nil transactionResponse:response] animated:YES];
            }
        }];
    };

   void (^deviceConnectionChangedBlock)(BOOL) = ^(BOOL conStatus){
       self.deviceStatus.text = (conStatus) ? @"Device Connected, swipe now" : @"Device Disconnected, connect please";
   };

    [NoHWCardReaderManager listenForCardsWithCallbackBlock:dataReadyBlock andDeviceConnectedBlock:deviceConnectionChangedBlock];
    self.deviceStatus.text = ([NoHWCardReaderManager isDeviceConnected]) ? @"Device Connected, swipe now" : @"Device Disconnected, connect please";

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewDidDisappear:(BOOL)animated {
    [NoHWCardReaderManager stopListening];
}

@end
