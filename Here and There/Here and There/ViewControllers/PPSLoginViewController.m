//
//  PPSLoginViewController.m
//  Here and There
//
//  Created by Metral, Max on 2/21/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>
#import "AFNetworking.h"
#import "PPSLoginViewController.h"
#import "NIInvocationMethods.h"
#import "NIUserInterfaceString.h"
#import "PPSProgressView.h"
#import "PPSNeedPayPalSetupViewController.h"
#import "PPSOrderEntryViewController.h"
#import "PPSAlertView.h"

#pragma mark -
#pragma mark Private members and methods

@interface PPSLoginViewController ()
#ifdef DEBUG
<
    NSNetServiceDelegate,
    NSNetServiceBrowserDelegate
>
#endif
@property (nonatomic,strong) UITextField *username;
@property (nonatomic,strong) UITextField *password;
@property (nonatomic,strong) UIButton *loginButton;

#ifdef DEBUG
@property (nonatomic,strong) NSNetServiceBrowser *browser;
@property (nonatomic,strong) NSNetService *service;
@property (nonatomic,strong) PPSProgressView *discoverySpinner;
#endif
@end

#ifdef DEBUG
NSString *sServiceHost = nil;
//NSString *sServiceHost = @"https://www.appsforhere.com/pphsdk"; // If you need it preconfigured

#endif

/**
 * For proper security, you need a server that securely stores the app id and secret for
 * PayPal Access. In order to prevent other applications and/or web sites from using your
 * back end service for their own purposes, and given that you likely have your own account
 * system, you should have the merchant login to your services first, and then authenticate
 * them when handing out URLs and exchanging tokens for authentication tokens.
 */
@implementation PPSLoginViewController

#pragma mark -
#pragma mark View Setup

-(void)loadView
{
    
#ifdef DEBUG
    if (!sServiceHost) {
        // In development, it's a little easier to test with devices if you don't have to configure a hostname/port
        // explicitly for every dev. So we'll use bonjour to find the service configured in the sample server.
        self.browser = [[NSNetServiceBrowser alloc] init];
        self.browser.delegate = self;
        [self.browser searchForServicesOfType: @"_hereandthere._tcp" inDomain:@""];
    }
#endif
    
    [super loadView];
    
    /* Create the view hierarchy using the super awesome Nimbus CSS view builder */
    [self.view buildSubviews:@[
     [UIView new], @"#container", @[
     (self.username = [UITextField new]), @"#username",
     [UIView new], @"#divider",
     (self.password = [UITextField new]), @"#password"
     ],
     (self.loginButton = [UIButton buttonWithType:UIButtonTypeCustom]), @"#login", @".primaryBtn",NIInvocationWithInstanceTarget(self, @selector(loginPressed:))
     ] inDOM:self.dom];
    
    // Further customization of runtime behavior that isn't supported in the stylesheet
    self.username.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.username.autocorrectionType = UITextAutocorrectionTypeNo;
    self.password.secureTextEntry = YES;
    
    self.username.text = [PPSPreferences currentUsername];
#ifdef DEBUG
    self.password.text = [PPSPreferences savedPasswordInDebug];
#endif
    
    [NILocalizedStringWithDefault(@"LoginViewTitle", @"Welcome to Here And There") attach:self withSelector:@selector(setTitle:)];
    self.edgesForExtendedLayout = UIRectEdgeNone;
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self.dom refresh];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.username becomeFirstResponder];
}

-(NSString *)stylesheetName
{
    return @"login";
}

#pragma mark -
#pragma mark Event Handlers

-(void)loginPressed: (id) sender
{
    __block PPSProgressView *progress = nil;
    [self.username resignFirstResponder];
    [self.password resignFirstResponder];
    
    [PPSPreferences setCurrentUsername:self.username.text];
#ifdef DEBUG
    [PPSPreferences setSavedPasswordInDebug:self.password.text];

    if (sServiceHost == nil) {
        self.discoverySpinner = [PPSProgressView progressViewWithTitle:@"Searching" andMessage:@"Finding Login Server..." withCancelHandler:^(PPSProgressView *progressView) {
            [self.discoverySpinner dismiss: YES];
            self.discoverySpinner = nil;
        }];
        return;
    }
#endif
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString: sServiceHost]];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login" parameters:@{
                             @"username": self.username.text,
                             @"password": self.password.text
                             }];
    request.timeoutInterval = 10;
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSON) {
        if (JSON && [JSON objectForKey:@"ticket"] && [JSON objectForKey:@"ticket"] != [NSNull null]) {
            
            // This is your credential for your service. We'll need it later for your server to give us an OAuth token
            // if we don't have one already
            NSString *ticket = [JSON objectForKey:@"ticket"];
            [PPSPreferences setCurrentTicket:ticket];

            // Find out if this account has already been setup for PayPal Access in our sample server "architecture"
            PPHMerchantInfo *merchantInfo = [PPSPreferences merchantFromServerResponse:JSON withMerchantId:self.username.text];

            if (merchantInfo) {
                [PayPalHereSDK setActiveMerchant:merchantInfo withMerchantId:self.username.text completionHandler:^(PPHAccessResultType status, PPHAccessAccount *account, NSDictionary *extraInfo) {
                    if (status == ePPHAccessResultSuccess) {
                        // Go to order entry view
                        [progress dismiss:YES];
                        PPSOrderEntryViewController *entry = [[PPSOrderEntryViewController alloc] init];
                        self.navigationController.viewControllers = @[entry];
                    } else {
                        NSAssert(NO, @"Failed to setup merchant.");
                    }
                }];
            } else {
                [progress dismiss:YES];
                self.navigationController.viewControllers = @[[[PPSNeedPayPalSetupViewController alloc] init]];
            }
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [progress dismiss:YES];
        [PPSAlertView showAlertViewWithTitle:@"Oops" message:error.localizedDescription buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
    }];
    
    progress = [PPSProgressView progressViewWithTitle:@"Logging In" andMessage:@"Contacting Server..." withCancelHandler:^(PPSProgressView *progressView) {
        [progress dismiss: YES];
        [operation cancel];
    }];
    [operation start];
}


#ifdef DEBUG
#pragma mark -
#pragma mark Net Service Handlers


-(void)netServiceBrowser:(NSNetServiceBrowser *)aNetServiceBrowser didFindService:(NSNetService *)aNetService moreComing:(BOOL)moreComing
{
    [self.browser stop];
    self.browser = nil;
    
    self.service = aNetService;
    aNetService.delegate = self;
    [aNetService resolveWithTimeout:15.0];
}

-(void)netServiceDidResolveAddress:(NSNetService *)sender
{
    sServiceHost = [NSString stringWithFormat:@"http://%@:%d/", sender.hostName, sender.port];
    if (self.discoverySpinner) {
        [self.discoverySpinner dismiss:NO];
        [self loginPressed:self];
        self.service = nil;
    }
}

-(void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict
{
    if (self.discoverySpinner) {
        [self.discoverySpinner dismiss:NO];
        [PPSAlertView showAlertViewWithTitle:@"Failed to Find Server" message:@"Make sure your sample server is running." buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
    }
}
#endif

@end
