//
//  LoginViewController.m
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "PaymentViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>


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
    // If you have the token saved already, use it else, off to PayPal we go.
    NSString *savedToken = [[NSUserDefaults standardUserDefaults] stringForKey:kSavedToken];
    if (savedToken) {
        [self initializeSDKMerchantWithToken:savedToken];
    } else {
        [self loginWithPayPal];
    }
}

#pragma mark -
#pragma PayPal & SDK related

- (void)loginWithPayPal {
    [self setWaitingForServer:YES];

    // Replace the url with your own sample server endpoint.
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kSavedToken];
    NSURL *url = [NSURL URLWithString:@"http://pph-retail-sdk-sample.herokuapp.com/toPayPal/live"];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)gotoPaymentScreen {
    [self setWaitingForServer:NO];

    PaymentViewController *paymentVC = [[PaymentViewController alloc] init];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:paymentVC];
    [appDelegate.window setRootViewController:navVC];
}

- (void)initializeSDKMerchantWithToken:(NSString *)token {
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

@end
