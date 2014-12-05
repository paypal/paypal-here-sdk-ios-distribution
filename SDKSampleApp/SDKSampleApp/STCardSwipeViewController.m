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
@property (nonatomic, retain) IBOutlet UIImageView *iphoneImageView;
@property (nonatomic, retain) IBOutlet UIImageView *swiperImageView;
@property (nonatomic, retain) IBOutlet UIImageView *cardImageView;
@property (nonatomic, copy) NSString *amount;
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
    PPHAmount *total = [PPHAmount amountWithString:self.amount];
    tm.ignoreHardwareReaders = NO;
    [tm beginPaymentWithAmount:total andName:@"simplePayment"];
    
    self.waitingForCardSwipe = YES;
    
    _activity.hidden = YES;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    _swiperActivityLabel.text = @"";
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self animateCard];
}

-(void)animateCard {
    CGRect originalFrame = self.cardImageView.frame;
    [UIView animateWithDuration:1.25 animations:^{
        [self.cardImageView setFrame:CGRectOffset(self.cardImageView.frame, 100, 0)];
    } completion:^(BOOL finished) {
        [self.cardImageView setFrame:originalFrame];
        if (self.view.window) {
            [self animateCard];
        }
    }];
    [UIView commitAnimations];
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
    if(event.eventType == ePPHTransactionType_CardReadBegun) {
        _swiperActivityLabel.text = @"Detecting a swipe...";
    } else if (event.eventType == ePPHTransactionType_FailedToReadCard) {
        _swiperActivityLabel.text = @"Swipe Failed.  Please try again";
    } else if (event.eventType == ePPHTransactionType_DidStartReaderDetection) {
        _swiperActivityLabel.text = @"Detecting a reader...";
    } else if (event.eventType == ePPHTransactionType_DidDetectReaderDevice) {
        _swiperActivityLabel.text = @"Successfully detected a swiper";
    } else if (event.eventType == ePPHTransactionType_DidRemoveReader) {
        _swiperActivityLabel.text = @"You removed the reader";
    } else if (event.eventType == ePPHTransactionType_CardDataReceived && self.waitingForCardSwipe)  {
          self.waitingForCardSwipe = NO;
        _swiperActivityLabel.text = @"Swipe Success!";
        
        _activity.hidden = NO;
        [_activity startAnimating];
        
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
