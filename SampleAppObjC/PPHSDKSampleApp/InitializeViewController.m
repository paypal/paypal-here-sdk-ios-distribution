//
//  InitializeViewController.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/18/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "InitializeViewController.h"
#import <SafariServices/SafariServices.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>

@interface InitializeViewController () <SFSafariViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UILabel *demoAppLbl;
@property (weak, nonatomic) IBOutlet UIButton *initializeSdkButton;
@property (weak, nonatomic) IBOutlet UIButton *initializeMerchantButton;
@property (weak, nonatomic) IBOutlet UILabel *merchEmailLabel;
@property (weak, nonatomic) IBOutlet UILabel *mercAcctLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activitySpinner;
@property (weak, nonatomic) IBOutlet UIButton *logoutBtn;
@property (weak, nonatomic) IBOutlet UIButton *initializeSdkInfoBtn;
@property (weak, nonatomic) IBOutlet UIButton *initializeMerchInfoBtn;
@property (weak, nonatomic) IBOutlet UISegmentedControl *envSelector;
@property (weak, nonatomic) IBOutlet UITextView *initializeMerchCode;
@property (weak, nonatomic) IBOutlet UITextView *initializeSdkCode;
@property (weak, nonatomic) IBOutlet UIView *merchInfoView;
@property (weak, nonatomic) IBOutlet UIButton *connectCardReaderBtn;
@end



@implementation InitializeViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Setting up initial aesthetics.
    [self.demoAppLbl setFont:[UIFont fontWithName:@"Helvetica-Bold" size:16.0]];
    self.merchInfoView.hidden = YES;
    self.initializeSdkCode.hidden = YES;
    self.initializeMerchCode.hidden = YES;
    self.initializeMerchantButton.enabled = NO;
    self.connectCardReaderBtn.hidden = YES;
    
    // Receive the notification that the token is being returned
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setupMerchant:) name:@"kCloseSafariViewControllerNotification" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)initSDK:(id)sender {
    self.initializeMerchantButton.enabled = YES;
    // First things first, we need to initilize the SDK itself.
    [PayPalRetailSDK initializeSDK];
    UIImage *btnImage = [UIImage imageNamed:@"small-greenarrow"];
    [self.initializeSdkButton setImage:btnImage forState: UIControlStateDisabled];
    self.initializeSdkButton.enabled = NO;
}

- (IBAction)initMerchant:(id)sender {
    self.envSelector.enabled = NO;
    self.activitySpinner.color = [UIColor blackColor];
    [self.activitySpinner startAnimating];
    [self performLogin];
}

- (IBAction)initSdkInfo:(id)sender {
    if(self.initializeSdkCode.hidden) {
        [self.initializeSdkInfoBtn setTitle:@"Hide Code" forState:UIControlStateNormal];
        self.initializeSdkCode.hidden = NO;
        [self.initializeSdkCode  setText:@"[PayPalRetailSDK initializeSDK];"];
    } else {
        [self.initializeSdkInfoBtn setTitle:@"View Code" forState:UIControlStateNormal];
        self.initializeSdkCode.hidden = YES;
    }
}

- (IBAction)initMerchantInfo:(id)sender {
    
    if(self.initializeMerchCode.hidden) {
        [self.initializeMerchInfoBtn setTitle:@"Hide Code" forState:UIControlStateNormal];
        self.initializeMerchCode.hidden = NO;
        self.initializeMerchCode.text = @"[PayPalRetailSDK initializeMerchantWithCredentials:(SdkCredential *)sdkCreds completionHandler:^(PPRetailError *error, PPRetailMerchant *merchant) {\n <code to handle success/failure> \n}];";
    } else {
        [self.initializeMerchInfoBtn setTitle:@"View Code" forState:UIControlStateNormal];
        self.initializeMerchCode.hidden = YES;
        if(![self.merchEmailLabel.text isEqualToString:@""]) {
            self.merchInfoView.hidden = NO;
        }
    }
}

- (IBAction)logout:(id)sender {
    // Clear out the UserDefaults and show the appropriate buttons/labels
    NSUserDefaults *tokenDefault =  [NSUserDefaults standardUserDefaults];
    [tokenDefault removeObjectForKey:@"ACCESS_TOKEN"];
    [tokenDefault removeObjectForKey:@"REFRESH_URL"];
    [tokenDefault removeObjectForKey:@"ENVIRONMENT"];
    [tokenDefault removeObjectForKey:@"MERCH_CURRENCY"];
    [tokenDefault synchronize];
    self.merchEmailLabel.text = @"";
    self.merchInfoView.hidden = YES;
    self.initializeMerchantButton.enabled = YES;
    UIImage *btnImage = [UIImage imageNamed:@"small-greenarrow"];
    [self.initializeMerchantButton setImage:btnImage forState: UIControlStateDisabled];
    self.envSelector.enabled = YES;
    self.connectCardReaderBtn.hidden = YES;
}

- (IBAction)goToDeviceDiscovery:(id)sender {
    [self performSegueWithIdentifier:@"showDeviceDiscovery" sender:sender];
}

- (void)setupMerchant:(NSNotification *)notification {
    
    // Dismiss the SFSafariViewController when the notification of token has been received.
    [[self presentedViewController] dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Successful dismissal");
    }];
    // Grab the token(s) from the notification and pass it into the merchant initialize call to set up
    // the merchant.  Upon successful initialization, the 'Connect Card Reader' button will be enabled for use.
    NSString *accessToken =  (NSString*) notification.object;
    NSUserDefaults *tokenDefault =  [NSUserDefaults standardUserDefaults];
    SdkCredential *sdkCreds = [[SdkCredential alloc] initWithAccessToken:accessToken refreshUrl:[tokenDefault stringForKey:@"REFRESH_URL"]  environment:[tokenDefault stringForKey:@"ENVIRONMENT"]];
    [PayPalRetailSDK initializeMerchantWithCredentials:(SdkCredential *)sdkCreds completionHandler:^(PPRetailError *error, PPRetailMerchant *merchant) {
        if (error != nil) {
          self.activitySpinner.color = [UIColor redColor];
          self.activitySpinner.hidesWhenStopped = NO;
          [self.activitySpinner stopAnimating];
          NSLog(@"Debug ID: %@",error.debugId);
          NSLog(@"Error Message: %@",error.code);
          NSLog(@"Error Code: %@",error.message);
          // The token did not work, so clear the saved token so we can go back to the login page
          [tokenDefault removeObjectForKey:@"ACCESS_TOKEN"];
        }
        NSLog(@"Merchant Success!");
        // Start watching for the audio reader
        [PayPalRetailSDK startWatchingAudio];
        self.activitySpinner.hidesWhenStopped = YES;
        [self.activitySpinner stopAnimating];
        UIImage *btnImage = [UIImage imageNamed:@"small-greenarrow"];
        [self.initializeMerchantButton setImage:btnImage forState: UIControlStateDisabled];
        self.initializeMerchantButton.enabled = NO;
        self.merchInfoView.hidden = NO;
        self.merchEmailLabel.text = merchant.emailAddress;
        // Save currency to UserDefaults for further usage. This needs to be used to initialize
        // the PPRetailInvoice for the payment later on. This app is using UserDefault but
        // it could just as easily be passed through the segue.
        [tokenDefault setValue:merchant.currency forKey:@"MERCH_CURRENCY"];
        [self setCurrencyType];
        // Add the BN code for Partner tracking. To obtain this value, contact
        // your PayPal account representative. Please do not change this value when
        // using this sample app for testing.
        merchant.referrerCode = @"PPHSDK_SampleApp_iOS";
        //Enable the connect card reader button here
        self.connectCardReaderBtn.hidden = NO;
    }];
    
}

-(void) setCurrencyType {
    NSUserDefaults *userDefaults =  [NSUserDefaults standardUserDefaults];
    NSString *merchantCurrency =  [userDefaults stringForKey:@"MERCH_CURRENCY"];
    if([merchantCurrency isEqualToString: @"GBP"]) {
        [userDefaults setValue:@"￡" forKey:@"CURRENCY_SYMBOL"];
    } else {
        [userDefaults setValue:@"$" forKey:@"CURRENCY_SYMBOL"];
    }
}


- (void) performLogin {
    // Set your URL for your backend server that handles OAuth.  This sample uses an instance of the
    // sample retail node server that's available at https://github.com/paypal/paypal-retail-node. To
    // set this to Live, simply change /sandbox to /live.  The returnTokenOnQueryString value tells
    // the sample server to return the actual token values instead of the compositeToken
    NSString *baseUrl = @"http://pph-retail-sdk-sample.herokuapp.com/toPayPal/";
    NSString *env = [self.envSelector titleForSegmentAtIndex:self.envSelector.selectedSegmentIndex];
    NSString *queryString = @"?returnTokenOnQueryString=true";
    NSURL *nsurl = [NSURL URLWithString:[[[NSArray alloc] initWithObjects:baseUrl, env, queryString,nil] componentsJoinedByString:@""]];
    
    // Check if there's a previous token saved in UserDefaults and, if so, use that.  This will also
    // check that the saved token matches the environment.  Otherwise, kick open the
    // SFSafariViewController to expose the login and obtain another token.
    NSUserDefaults *tokenDefault =  [NSUserDefaults standardUserDefaults];

    if(([tokenDefault stringForKey:@"ACCESS_TOKEN"] != nil) && (env == [tokenDefault stringForKey:@"ENVIRONMENT"])) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kCloseSafariViewControllerNotification" object:[tokenDefault stringForKey:@"ACCESS_TOKEN"]];
    } else {
       // Present a SFSafariViewController to handle the login to get the merchant account to use.
       SFSafariViewController *svc = [[SFSafariViewController alloc] initWithURL:nsurl];
       [svc setDelegate: self];
       [self presentViewController:svc animated:YES completion:nil];
    }
}

// This function would be called if the user pressed the Done button inside the SFSafariViewController.
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    [self.activitySpinner stopAnimating];
    self.initializeMerchantButton.enabled = YES;
    self.envSelector.enabled = YES;
}

@end
