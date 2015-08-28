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

@property (nonatomic, retain) IBOutlet UIButton *loginButton;

@end

@implementation LoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

- (void)setupView {
    [self.view setBackgroundColor:[UIColor whiteColor]];
    [self setupLoginButton];
}

- (void)setupLoginButton {
    CGRect viewFrame = self.view.frame;
    self.loginButton = [[UIButton alloc] initWithFrame:CGRectMake((viewFrame.size.width - 100) /2, viewFrame.size.height/2, 100, 50)];
    [self.loginButton setTitle:@"Login" forState:UIControlStateNormal];
    [self.loginButton setBackgroundColor:[UIColor blueColor]];
    [self.loginButton addTarget:self action:@selector(loginButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.loginButton];
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
    // Replace the url with your own sample server endpoint.
    NSURL *url = [NSURL URLWithString:@"http://pph-retail-sdk-sample.herokuapp.com/toPayPal/live"];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)gotoPaymentScreen {
    PaymentViewController *paymentVC = [[PaymentViewController alloc] init];
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:paymentVC];
    [appDelegate.window setRootViewController:navVC];
}

- (void)initializeSDKMerchantWithToken:(NSString *)token {
    __weak typeof(self) weakSelf = self;
    // Initialize the SDK with the token.
    [PayPalHereSDK setupWithCompositeTokenString:token
                           thenCompletionHandler:^(PPHInitResultType status, PPHError *error, PPHMerchantInfo *info) {
                               [weakSelf gotoPaymentScreen];
                           }];
}

@end
