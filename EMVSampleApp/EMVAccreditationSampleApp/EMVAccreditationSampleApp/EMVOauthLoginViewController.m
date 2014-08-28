//
//  ViewController.m
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "EMVOauthLoginViewController.h"
#import "EMVTransactionViewController.h"
#import "PPSPreferences.h"
#import "PPSCryptoUtils.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface EMVOauthLoginViewController ()
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@end

@implementation EMVOauthLoginViewController

#pragma mark
#pragma mark - View Controller Setup and Tear Down Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setUpSegmentedControlAndServiceUrls];
    [self setUpSpinnerAndTitle];
    [self setUpTextFields];
    self.loginButton.layer.cornerRadius = 10;

}

- (void)viewWillAppear:(BOOL)animated {
    
    [self clearTextFields];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpSegmentedControlAndServiceUrls {
    
    [self.segControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    
    self.serviceHostUrlArray = [[NSMutableArray alloc] init];
    
    [self.serviceHostUrlArray addObject:[[NSMutableString alloc]
                                         initWithString:@"http://stormy-hollows-1584.herokuapp.com"]];
    
    [self.serviceHostUrlArray addObject:[[NSMutableString alloc]
                                         initWithString:@"http://desolate-wave-3684.herokuapp.com"]];
    
    [self.serviceHostUrlArray addObject:[[NSMutableString alloc]
                                         initWithString:@"http://hidden-spire-8232.herokuapp.com/server"]];
    
    self.sdkBaseUrlArray = [[NSMutableArray alloc] init];
    [self.sdkBaseUrlArray addObject:[NSNull null]];
    [self.sdkBaseUrlArray addObject:@"https://www.sandbox.paypal.com/webapps/"];
    [self.sdkBaseUrlArray addObject:@"https://www.stage2mb001.stage.paypal.com/webapps/"];
    
    
    
}

- (void)setUpSpinnerAndTitle {
    self.spinner.hidesWhenStopped = YES;
    self.title = @"Emv Sample App";
}

- (void)setUpTextFields {
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
    self.passwordField.secureTextEntry = YES;
}

- (void)clearTextFields {
    self.usernameField.text = nil;
    self.passwordField.text = nil;
}

- (BOOL)fieldValidation {
    
    if (self.usernameField.text && self.passwordField.text) {
        return YES;
    }
    
    return NO;
    
}

#pragma mark
#pragma mark - Delegate Callbacks and IBActions
- (IBAction)usernameFieldReturned:(id)sender {
    [sender resignFirstResponder];
    [self resetTextFieldOffset];
}

- (IBAction)passwordFieldReturned:(id)sender {
    [sender resignFirstResponder];
    [self resetTextFieldOffset];
}

- (IBAction)serviceHostSegmentedControlChanged:(id)sender {
    
    if (self.segControl.selectedSegmentIndex == 0) {
        self.serviceHostUrl = [self.serviceHostUrlArray objectAtIndex:0];
        self.urlForTheSdkToUse = [self.sdkBaseUrlArray objectAtIndex:0];
        [PayPalHereSDK selectEnvironmentWithType:ePPHSDKServiceType_Live];
    }
    
    else if (self.segControl.selectedSegmentIndex == 1) {
        self.serviceHostUrl = [self.serviceHostUrlArray objectAtIndex:1];
        self.urlForTheSdkToUse = [self.sdkBaseUrlArray objectAtIndex:1];
        [PayPalHereSDK selectEnvironmentWithType:ePPHSDKServiceType_Sandbox];
    }
    
    else {
        self.serviceHostUrl = [self.serviceHostUrlArray objectAtIndex:2];
        self.urlForTheSdkToUse = [self.sdkBaseUrlArray objectAtIndex:2];
        [PayPalHereSDK setBaseAPIURL:[NSURL URLWithString:self.urlForTheSdkToUse]];
    }
    
    NSLog(@"Service Host Url we will use for login %@", self.serviceHostUrl);
    NSLog(@"Url the PayPal Here SDK will be using: %@", self.urlForTheSdkToUse);
    
}

- (IBAction)loginPressed:(id)sender {
    
    if (self.segControl.selectedSegmentIndex != UISegmentedControlNoSegment && [self fieldValidation]) {
        
        [self.view endEditing:YES];
        [self resetTextFieldOffset];
        [self.spinner startAnimating];
        
        NSMutableURLRequest *request = [self createLoginRequest];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            if(data == nil && response == nil) {
                [self showAlertWithTitle:@"Login Failed" andMessage:@"Is the internet connection offline?"];
                return;
            }
            
            NSError *error = nil;
            NSDictionary* jsonResponse = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:kNilOptions
                                  error:&error];
            
            if (!jsonResponse || ![jsonResponse objectForKey:@"merchant"]) {
                [self showAlertWithTitle:@"Login Failed." andMessage:@"The Heroku sample server returned an ambiguous response."];
                [self.spinner stopAnimating];
            }
            
            else {
                
                [self loadMerchantObjectFromHerokuResponse:jsonResponse];
                
                NSString *ticket = [jsonResponse objectForKey:@"ticket"];
                [PPSPreferences setCurrentTicket:ticket];
                
                if (!ticket) {
                    [self showAlertWithTitle:@"Login Failed" andMessage:@"We did not get back a session ticket for the provided username and password combination"];
                }
                
                if ([jsonResponse objectForKey:@"access_token"]) {
                    // The access token exists!   The user must have previously logged into
                    // the sample server.  Let's give these credentials to the SDK and conclude
                    // the login process.
                    [self setActiveMerchantWithAccessTokenDict:jsonResponse];
                }
                else {
                    // We don't have an access_token?  Then we need to login to PayPal's oauth process.
                    // Let's procede to that step.
                    [self loginToPayPal:ticket];
                }
                
                
            }
            
            
        }];
        
    }
    
    else {
        [self showAlertWithTitle:@"Login Failed." andMessage:@"Please select a sevice host type from the segmented control"];
    }
    
}

#pragma mark
#pragma mark - PayPal Login, and Merchant Initialize Functions
- (void) loginToPayPal:(NSString *)ticket
{
  	NSLog(@"Logging in to PayPal...");
    
    NSMutableURLRequest *request = [self createGoPayPalRequest:ticket];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        NSError *error = nil;
        NSDictionary *jsonResponse = [NSJSONSerialization
                                      JSONObjectWithData:data
                                      options:kNilOptions
                                      error:&error];
        
        if (jsonResponse) {
			
			if ([jsonResponse objectForKey:@"url"] && [[jsonResponse objectForKey:@"url"] isKindOfClass:[NSString class]]) {
                
                // FIRE UP SAFARI TO LOGIN TO PAYPAL
                // \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_
                NSString *url = [jsonResponse objectForKey:@"url"];
                NSLog(@"Pointing Safari at URL [%@]", url);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
                
			} else if ([jsonResponse objectForKey:@"access_token"]) {
                
                [self setActiveMerchantWithAccessTokenDict:jsonResponse];
            }
			else {
                
                // UH-OH - NO URL FOR SAFARI TO FOLLOW, NO ACCESS TOKEN FOR YOU. FAIL.
                // \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_
                NSLog(@"FAILURE! Got neither a URL to point Safari to, nor an Access Token - Huh?");
                [self showAlertWithTitle:@"Login failed." andMessage:@"We attempted to communicate PayPal's login servers, but their response was ambiguous"];
                [self.spinner stopAnimating];
			}
            
        }
        else {
			[self showAlertWithTitle:@"Login failed." andMessage:@"We attempted to communicate PayPal's login servers, but their response was ambiguous"];
            [self.spinner stopAnimating];
        }
        
        
    }];
}

- (void) setActiveMerchantWithAccessTokenDict:(NSDictionary *)JSON
{
	NSString* key = [PPSPreferences currentTicket]; // The sample server encrypted the access token using the 'ticket' it returned in step 1 (the /login call)
	NSString* access_token = [JSON objectForKey:@"access_token"];
	NSString* access = [PPSCryptoUtils AES256Decrypt:access_token  withPassword:key];
    
	if (key == nil || access == nil) {
        
		NSLog(@"Bailing because couldn't decrypt access_code.   key: %@   access: %@   access_token: %@", key, access, access_token);
        
        [self showAlertWithTitle:@"Login Failed." andMessage:@"Ticket decryption failure."];
        
		return;
	}
    
	PPHAccessAccount *account = [[PPHAccessAccount alloc] initWithAccessToken:access
                                                                   expires_in:[JSON objectForKey:@"expires_in"]
                                                                   refreshUrl:[JSON objectForKey:@"refresh_url"] details:JSON];
    self.merchant.payPalAccount = account;
    
    [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:@"lastgoodusername"];
    
	[PayPalHereSDK setActiveMerchant:self.merchant
                      withMerchantId:self.merchant.invoiceContactInfo.businessName
				   completionHandler: ^(PPHAccessResultType status, PPHAccessAccount* account, NSDictionary* extraInfo) {
                       
                       if (status == ePPHAccessResultSuccess) {
                           
                           //Let's update our Merchant object, then refeed it into the SDK
                           //when that thread comes back with a success we can transition to the
                           //next View Controller..
                           //TO DO: Make Heroku App return the correct merchant data...
                           
                           [self loadMerchantObjectFromPPAccessResponseObject:account];
                           [PayPalHereSDK setActiveMerchant:self.merchant withMerchantId:self.merchant.invoiceContactInfo.businessName completionHandler:^(PPHAccessResultType status, PPHAccessAccount *account, NSDictionary *extraInfo) {
                               
                               if (status == ePPHAccessResultSuccess) {
                                   [self.spinner stopAnimating];
                                   [self transitionToTheNextViewController];
                               }
                               
                           }];
                           
                       }
                       
                       else {
                           
                           [self showAlertWithTitle:@"Login Failed." andMessage:@"We were unable to set an active merchant for the provided username and password credentials."];
                           [self.spinner stopAnimating];
                           
                       }
                       
                   }];
    
}

- (NSMutableURLRequest *)createLoginRequest {
    
    NSMutableString *urlString = [[NSMutableString alloc] initWithString:self.serviceHostUrl];
    [urlString appendString:@"/login"];
    
    NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    
    [loginRequest setHTTPMethod:@"POST"];
    
    NSMutableString *loginRequestPostString =[[NSMutableString alloc] init];
    [loginRequestPostString appendString:@"username="];
    [loginRequestPostString appendString:self.usernameField.text];
    [loginRequestPostString appendString:@"&password="];
    [loginRequestPostString appendString:self.passwordField.text];
    [loginRequestPostString appendString:@"&servername="];
    [loginRequestPostString appendString:@"stage2mb001"];
    
    [loginRequest setHTTPBody:[loginRequestPostString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return loginRequest;
    
}

- (NSMutableURLRequest *) createGoPayPalRequest:(NSString *)ticket {
    
    NSMutableString *urlString = [[NSMutableString alloc] initWithString:self.serviceHostUrl];
    [urlString appendString:@"/goPayPal"];
    
    NSMutableURLRequest *loginRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    
    [loginRequest setHTTPMethod:@"POST"];
    
    NSMutableString *loginRequestPostString =[[NSMutableString alloc] init];
    [loginRequestPostString appendString:@"username="];
    [loginRequestPostString appendString:self.usernameField.text];
    [loginRequestPostString appendString:@"&ticket="];
    [loginRequestPostString appendString:ticket];
    [loginRequestPostString appendString:@"&servername="];
    [loginRequestPostString appendString:@"stage2mb001"];
    
    [loginRequest setHTTPBody:[loginRequestPostString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return loginRequest;
    
}

#pragma mark
#pragma mark - Generic Helper methods
- (void)loadMerchantObjectFromHerokuResponse:(NSDictionary *)responseDict {
    
    NSDictionary *yourMerchant = [responseDict objectForKey:@"merchant"];
    
    self.merchant = [[PPHMerchantInfo alloc] init];
    self.merchant.invoiceContactInfo = [[PPHInvoiceContactInfo alloc]
                                        initWithCountryCode: [yourMerchant objectForKey:@"country"]
                                        city:[yourMerchant objectForKey:@"city"]
                                        addressLineOne:[yourMerchant objectForKey:@"line1"]];
    
    self.merchant.invoiceContactInfo.businessName = [yourMerchant objectForKey:@"businessName"];
    self.merchant.invoiceContactInfo.state = [yourMerchant objectForKey:@"state"];
    self.merchant.invoiceContactInfo.postalCode = [yourMerchant objectForKey:@"postalCode"];
    self.merchant.currencyCode = [yourMerchant objectForKey:@"currency"];
    
}

- (void)loadMerchantObjectFromPPAccessResponseObject:(PPHAccessAccount *)accountResp {
    
    NSDictionary *responseDict = accountResp.extraInfo;
    NSDictionary *addressInformation = [responseDict objectForKey:@"address"];
    self.merchant.invoiceContactInfo = [[PPHInvoiceContactInfo alloc]
                                        initWithCountryCode: [addressInformation objectForKey:@"country"]
                                        city: [addressInformation objectForKey:@"locality"]
                                        addressLineOne: [addressInformation objectForKey:@"street_address"]];
    
    self.merchant.invoiceContactInfo.businessName = [responseDict objectForKey:@"businessName"];
    self.merchant.invoiceContactInfo.state = [addressInformation objectForKey:@"region"];
    self.merchant.invoiceContactInfo.postalCode = [addressInformation objectForKey:@"postal_code"];
    self.merchant.currencyCode = accountResp.currencyCode;
}

- (void)transitionToTheNextViewController
{
	EMVTransactionViewController *transactionVC = [[EMVTransactionViewController alloc]
                         initWithNibName:@"EMVTransactionViewController_iPhone"
                         bundle:nil];
    
    transactionVC.title = @"Order Entry";
    self.navigationController.viewControllers = @[transactionVC];
}

-(void) showAlertWithTitle:(NSString *)title andMessage:(NSString *)message {
    UIAlertView *alertView =
    [[UIAlertView alloc]
     initWithTitle:title
     message: message
     delegate:nil
     cancelButtonTitle:@"OK"
     otherButtonTitles:nil];
    
    [alertView show];
}

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    if (textField == self.usernameField || textField == self.passwordField) {
        [UIView animateWithDuration:.5 animations:^{
            [self.view setFrame:CGRectMake(0, -150, self.view.frame.size.width, self.view.frame.size.height)];
        }];
        [UIView commitAnimations];
    }
}

-(void)resetTextFieldOffset {
        [UIView animateWithDuration:.4 animations:^{
            [self.view setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
        }];
        [UIView commitAnimations];
}

@end
