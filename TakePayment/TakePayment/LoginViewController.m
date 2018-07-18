//
//  LoginViewController.m
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

#define SAVED_TOKEN @"savedToken"
#define SAVED_ACCESS_TOKEN @"savedAccessToken"
#define SAVED_REFRESH_URL @"savedRefreshUrl"

@interface LoginViewController ()

@property (nonatomic, strong) UIButton *loginButton;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;

@end

@implementation LoginViewController

- (void)loadView {
    [super loadView];
   
    [self.view setBackgroundColor:[UIColor whiteColor]];

    CGRect viewFrame = self.view.frame;
    self.loginButton = [[UIButton alloc] initWithFrame:CGRectMake((viewFrame.size.width - 100) /2, viewFrame.size.height/2, 100, 50)];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.loginButton setBackgroundColor:[UIColor blueColor]];
    [self.loginButton addTarget:self action:@selector(loginButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.frame = self.loginButton.frame;

    [self.view addSubview:self.spinner];

    
    [self setWaitingForServer:NO];
}

- (void)setWaitingForServer:(BOOL)waitingForServer {
    self.loginButton.hidden = waitingForServer;
    self.spinner.hidden = !waitingForServer;
    if (self.spinner.hidden) {
        [self.spinner stopAnimating];
    } else {
        [self.spinner startAnimating];
    }
}

- (void)loginButtonPressed {
    NSString *savedAccessToken = [[NSUserDefaults standardUserDefaults] stringForKey:SAVED_ACCESS_TOKEN];
    NSString *savedRefreshUrl = [[NSUserDefaults standardUserDefaults] stringForKey:SAVED_REFRESH_URL];
    
    if (savedAccessToken && savedRefreshUrl) {
        [self initializeSDKMerchantWithCredentials:savedAccessToken refreshUrl:savedRefreshUrl];
    } else {
        [self loginWithPayPal];
    }
}

- (void)forgetTokens {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SAVED_TOKEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SAVED_ACCESS_TOKEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:SAVED_REFRESH_URL];
}
#pragma mark -
#pragma PayPal & SDK related

- (void)loginWithPayPal {
    [self setWaitingForServer:YES];

    // Replace the url with your own sample server endpoint.
    [self forgetTokens];
    NSURL *url = [NSURL URLWithString:@"http://pph-retail-sdk-sample.herokuapp.com/toPayPal/live"];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)gotoPaymentScreen {
    [self setWaitingForServer:NO];
    
    [self.navigationController pushViewController:((AppDelegate *)[UIApplication sharedApplication].delegate).paymentVC animated:YES];
}

- (void)initializeSDKMerchantWithToken:(NSString *)token {
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:SAVED_TOKEN];
    [self setWaitingForServer:YES];
    
    __weak typeof(self) weakSelf = self;
    // Initialize the SDK with the token.
    [PayPalHereSDK setupWithCompositeTokenString:token
                           thenCompletionHandler:^(PPHInitResultType status, PPHError *error, PPHMerchantInfo *info) {
                               if (error) {
                                   [weakSelf loginWithPayPal];
                               } else {
                                   [weakSelf gotoPaymentScreen];
                               }
                           }];
}

- (void)initializeSDKMerchantWithCredentials:(NSString *)access_token refreshUrl:(NSString *)refresh_url  {
    [[NSUserDefaults standardUserDefaults] setObject:access_token forKey:SAVED_ACCESS_TOKEN];
    [[NSUserDefaults standardUserDefaults] setObject:refresh_url forKey:SAVED_REFRESH_URL];
    [self setWaitingForServer:YES];
    
    __weak typeof(self) weakSelf = self;
    // Initialize the SDK with the token.
    [PayPalHereSDK selectEnvironmentWithType:ePPHSDKServiceType_Live];
    [PayPalHereSDK setupWithCredentials:access_token refreshUrl:refresh_url tokenExpiryOrNil:nil                            thenCompletionHandler:^(PPHInitResultType status, PPHError *error, PPHMerchantInfo *info) {
                               if (error) {
                                   [weakSelf loginWithPayPal];
                               } else {
                                   [weakSelf gotoPaymentScreen];
                               }
                           }];
}

@end
