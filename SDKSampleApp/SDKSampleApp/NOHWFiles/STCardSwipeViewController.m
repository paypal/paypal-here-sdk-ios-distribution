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
#import "MTSCRA.h"

#import <PayPalHereSDK/PPHCardSwipeData.h>
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface STCardSwipeViewController ()
@property (nonatomic, retain) IBOutlet UIImageView *swipeImageView;
@property (nonatomic, retain) IBOutlet UILabel *deviceStatus;
@property (nonatomic, strong) NSString *amount;
@property (nonatomic, strong) PPHCardSwipeData *data;
@property (nonatomic, strong) MTSCRA *mtSCRALib;
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
    
    self.mtSCRALib = [[MTSCRA alloc] init];
    [self.mtSCRALib listenForEvents:(TRANS_EVENT_OK|TRANS_EVENT_START|TRANS_EVENT_ERROR)];

    //Audio
    [self.mtSCRALib setDeviceType:(MAGTEKAUDIOREADER)];
    BOOL hi = [self.mtSCRALib openDevice];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(trackDataReady:) name:@"trackDataReadyNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(devConnStatusChange) name:@"devConnectionNotification" object:nil];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)trackDataReady:(NSNotification *)notification {
    NSNumber *status = [[notification userInfo] valueForKey:@"status"];
    [self performSelectorOnMainThread:@selector(onDataEvent:) withObject:status waitUntilDone:YES];
}

- (void)onDataEvent:(id)status
{
    NSLog(@"----------%d---------", [status intValue]);
    if ([status intValue] == TRANS_STATUS_OK) {
        [[PayPalHereSDK sharedTransactionManager] beginPaymentWithAmount:[PPHAmount amountWithString:_amount inCurrency:@"USD"] andName:@"amount"];
        PPHCardSwipeData *swipeData = [[PPHCardSwipeData alloc] initWithTrack1:[self.mtSCRALib getTrack1] track2:[self.mtSCRALib getTrack2] readerSerial:[self.mtSCRALib getDeviceSerial] withType:@"MAGTEK" andExtraInfo:@{@"ksn":[self.mtSCRALib getKSN]}];
        [swipeData parseTracks:[self.mtSCRALib getMaskedTracks]];
        [PayPalHereSDK sharedTransactionManager].encryptedCardData = swipeData;
        [[PayPalHereSDK sharedTransactionManager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe withTransactionController:nil completionHandler:^(PPHTransactionResponse *response){
            NSLog(@"HERE");
        }];
    }
}

- (void)devConnStatusChange
{
    BOOL isDeviceConnected = [self.mtSCRALib isDeviceConnected];
    if (isDeviceConnected)
    {
        self.deviceStatus.text = @"Device Connected"; }
    else
    {
        self.deviceStatus.text = @"Device Disconnected";
    }
}
@end
