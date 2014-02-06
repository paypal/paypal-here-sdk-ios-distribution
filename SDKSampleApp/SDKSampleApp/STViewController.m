//
//  STViewController.m
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/14/13.
//  Copyright (c) 2013 PayPalHereSDK. All rights reserved.
//

#import "AFNetworking.h"
#import "STViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

#define sServiceHost @"http://morning-tundra-8515.herokuapp.com/"

@interface STViewController ()

@end

@implementation STViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	self.title = @"OAuth Login";
	self.usernameField.delegate = self;
	self.passwordField.delegate = self;

	[[PayPalHereSDK sharedCardReaderManager] beginMonitoring];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginPressed:(id)sender {
  	NSLog(@"Logging in...");

    if (!self.usernameField.text.length) {
        [self.usernameField becomeFirstResponder];
    }
    else if (!self.passwordField.text.length) {
        [self.passwordField becomeFirstResponder];
    }
    else {
        [self dismissKeyboard];
    }

	self.loginInProgress.hidden = NO;

    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString: sServiceHost]];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login" parameters:@{
                             @"username": self.usernameField.text,
                             @"password": self.passwordField.text
                             }];
    request.timeoutInterval = 10;
    
    AFJSONRequestOperation *operation = 
	  [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSON) {

		  self.loginInProgress.hidden = YES;

		  if (JSON) {
			  NSLog(@"We got some JSON back: [%@]", JSON);
			  if ([JSON objectForKey:@"merchant"]) {
				  NSLog(@"SUCCESSFUL LOGIN!");
			  }
			  else {
				  UIAlertView *alertView = 
					  [[UIAlertView alloc]
						  initWithTitle:@"Login Failed - Username Problem?"
								message:@"Check your Username and Password and try again."
							   delegate:nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil];
											   
				  [alertView show];

				  NSLog(@"LOGIN FAILURE!");
			  }
		  }
		  else {
			  UIAlertView *alertView = 
			  [[UIAlertView alloc]
						  initWithTitle:@"Login Failed"
								message: 
					  @"Server returned an ambiguous response (nil JSON dictionary). "
				  @"Check your Username and Password and try again. "
				  @"If problem continues, might be a good idea to see if the server is healthy ["
				  sServiceHost @"]"
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil];
											   
			  [alertView show];

			  NSLog(@"Call succeeded, apparently - but we got a nil JSON dict");
		  }

		  } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

			  self.loginInProgress.hidden = YES;

			  UIAlertView *alertView = 
			  [[UIAlertView alloc]
						  initWithTitle:@"Login Failed"
								message:@"Check your Username and Password and try again."
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil];
											   
			  [alertView show];

			  NSLog(@"The Heroku login call failed: [%@]", error);

		  }];
    
    [operation start];

	NSLog(@"Attempting to login to Heroku as \"%@\" with password \"%@\"...", self.usernameField.text, self.passwordField.text);


}

- (void)dismissKeyboard
{
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.usernameField isFirstResponder]) {
        [self.passwordField becomeFirstResponder];
    } 
    else {
        [self dismissKeyboard];
    }
    
    return NO;
}



@end
