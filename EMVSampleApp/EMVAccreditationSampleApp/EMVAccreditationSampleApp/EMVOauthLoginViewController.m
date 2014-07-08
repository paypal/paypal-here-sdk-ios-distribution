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

@end

@implementation EMVOauthLoginViewController

#pragma mark
#pragma mark - View Controller Setup

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setUpSegmentedControlAndServiceUrls];
    [self disableTextFields];
    [self setUpSpinnerAndAlertView];
    self.title = @"Emv Sample App";

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
                                         initWithString:@"http://morning-tundra-8515.herokuapp.com"]];
    
    self.sdkBaseUrlArray = [[NSMutableArray alloc] init];
    [self.sdkBaseUrlArray addObject:[NSNull null]];
    [self.sdkBaseUrlArray addObject:@"https://www.sandbox.paypal.com/webapps/"];
    [self.sdkBaseUrlArray addObject:@"https://www.stage2mb006.stage.paypal.com/webapps/"];
    
}

- (void)setUpSpinnerAndAlertView {
    
    self.spinner.hidesWhenStopped = YES;
    self.noServiceHostSelectedAlert.delegate = self;
    
    self.noServiceHostSelectedAlert = [[UIAlertView alloc] initWithTitle:@"Login failed" message:@"Please select a service host mode/type from the segmented control." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];

}

- (void)disableTextFields {
    
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;
    
    [self.usernameField setUserInteractionEnabled:NO];
    [self.passwordField setUserInteractionEnabled:NO];
    
}

#pragma mark
#pragma mark - Delegate Callbacks and IBActions

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
    
    if (self.segControl.selectedSegmentIndex != UISegmentedControlNoSegment) {
        
        [self.spinner startAnimating];
        
        NSMutableURLRequest *request = [self createLoginRequest];
        
        [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
            
            NSError *error = nil;
            NSDictionary* jsonResponse = [NSJSONSerialization
                                  JSONObjectWithData:data
                                  options:kNilOptions
                                  error:&error];
            
            if (!jsonResponse || ![jsonResponse objectForKey:@"merchant"]) {
                
                //fail out, we should say the Heroku server returned an ambiguous response
                
            }
            
            else {
                
                //let us fill out and create a Merchant object
                //we will feed this in to the SDK
                
                NSString *ticket = [jsonResponse objectForKey:@"ticket"];
                [PPSPreferences setCurrentTicket:ticket];
                
                if (!ticket) {
                    //show alert here, ticket should not be nil
                }
                
                NSDictionary *yourMerchant = [jsonResponse objectForKey:@"merchant"];
                
                self.merchant = [[PPHMerchantInfo alloc] init];
                self.merchant.invoiceContactInfo = [[PPHInvoiceContactInfo alloc]
                                                    initWithCountryCode: [yourMerchant objectForKey:@"country"]
                                                    city:[yourMerchant objectForKey:@"city"]
                                                    addressLineOne:[yourMerchant objectForKey:@"line1"]];
                
                self.merchant.invoiceContactInfo.businessName = [yourMerchant objectForKey:@"businessName"];
                self.merchant.invoiceContactInfo.state = [yourMerchant objectForKey:@"state"];
                self.merchant.invoiceContactInfo.postalCode = [yourMerchant objectForKey:@"postalCode"];
                self.merchant.currencyCode = [yourMerchant objectForKey:@"currency"];
                
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
        
        [self.noServiceHostSelectedAlert show];
        
    }
    
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
    
    [loginRequest setHTTPBody:[loginRequestPostString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return loginRequest;
    
}

#pragma mark 
#pragma mark - Helper methods

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
			NSLog(@"PayPal login attempt got some JSON back: [%@]", jsonResponse);
            
			if ([jsonResponse objectForKey:@"url"] && [[jsonResponse objectForKey:@"url"] isKindOfClass:[NSString class]]) {
                
                // FIRE UP SAFARI TO LOGIN TO PAYPAL
                // \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_
                NSString *url = [jsonResponse objectForKey:@"url"];
                NSLog(@"Pointing Safari at URL [%@]", url);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
			}
			else {
                
                // UH-OH - NO URL FOR SAFARI TO FOLLOW, NO ACCESS TOKEN FOR YOU. FAIL.
                // \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_
                NSLog(@"FAILURE! Got neither a URL to point Safari to, nor an Access Token - Huh?");
                
                //show some alert
                
			}
            
        }
        else {
			NSLog(@"PayPal login attempt got no JSON back!");
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
       
        //show some alert here
        
		return;
	}
    
    // We have valid credentials.
    // The login process has been successful.  Here we complete the process.
    // Let's package them up the credentails into a PPHAccessAcount object and set that
    // object into the PPHMerchant object we're building.
	PPHAccessAccount *account = [[PPHAccessAccount alloc] initWithAccessToken:access
                                                                   expires_in:[JSON objectForKey:@"expires_in"]
                                                                   refreshUrl:[JSON objectForKey:@"refresh_url"] details:JSON];
	self.merchant.payPalAccount = account;  // Set the credentails into the merchant object.
    
    // Since this is a successful login, let's save the user name so we can use it as the default username the next
    // time the sample app is run.
    [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:@"lastgoodusername"];
    
    // Call setActiveMerchant
    // This is how we configure the SDK to use the merchant info and credentails.
    // Provide the PPHMerchant object we've built, and a key which the SDK will use to uniquely store this merchant's
    // contact information.
    // NOTE: setActiveMerchant will kick off two network requests to PayPal.  These calls request detailed information
    // about the merchant needed so we can take payment for this merchant.  Once those calls are done the completionHandler
    // block will be called.  If successful, status will be ePPHAccessResultSuccess.  Only if this returns successful
    // will the SDK be able to take payment, do invoicing related operations, or do checkin operations for this merchant.
    //
    // Please wait for this call to complete before attempting other SDK operations.
    //
	[PayPalHereSDK setActiveMerchant:self.merchant
                      withMerchantId:self.merchant.invoiceContactInfo.businessName
				   completionHandler: ^(PPHAccessResultType status, PPHAccessAccount* account, NSDictionary* extraInfo) {
                       
                       if (status == ePPHAccessResultSuccess) {
                           // Login complete!
                           // Time to show the sample app UI!
                           //
                           
                           //let's move to the next view controller and let's stop the spinner
                           [self.spinner stopAnimating];
                           [self transitionToTheNextViewController];
                           
                       }
                       
                       else {
                           
                           NSLog(@"We have FAILED to setActiveMerchant from setActiveMerchantWithAccessTokenDict, showing error Alert.");
                           
                           //display an alert here
                           
                       }
                       
                   }];
    
}

- (void)transitionToTheNextViewController
{
	EMVTransactionViewController *transactionVC = nil;
    
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		transactionVC = [[EMVTransactionViewController alloc]
                         initWithNibName:@"EMVTransactionViewController_iPhone"
                         bundle:nil];
	}
	else {
        NSLog(@"stepping in ipad detection");
		transactionVC = [[EMVTransactionViewController alloc]
                         initWithNibName:@"EMVTransactionViewController_iPad"
                         bundle:nil];
	}
    
    self.navigationController.viewControllers = @[transactionVC];
}

@end
