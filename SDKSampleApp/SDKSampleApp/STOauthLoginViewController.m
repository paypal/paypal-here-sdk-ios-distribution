//
//  STViewController.m
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/14/13.
//  Copyright (c) 2013 PayPalHereSDK. All rights reserved.
//

#import "PPSPreferences.h"
#import "PPSCryptoUtils.h"

#import "AFNetworking.h"
#import "STOauthLoginViewController.h"
#import "STTransactionViewController.h"

#import <PayPalHereSDK/PayPalHereSDK.h>

#define sServiceHost @"http://morning-tundra-8515.herokuapp.com/"

@interface STOauthLoginViewController ()

@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) NSArray *pickerViewArray;
@property (nonatomic, strong) NSArray *pickerURLArray;
@property (nonatomic, strong) NSArray *serviceArray;
@property (nonatomic, strong) NSString *serviceHost;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation STOauthLoginViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

	self.title = @"PayPal Login via OAuth";
	self.usernameField.delegate = self;
	self.passwordField.delegate = self;

	[self.scrollView 
		 setContentSize:CGSizeMake(CGRectGetWidth(self.scrollView.frame),
								   CGRectGetHeight(self.scrollView.frame)
			)];

	[self createPicker];

	// Initialize the URL label to the currently selected Service:
	NSString *initialServiceHost = [self.pickerURLArray objectAtIndex:[self.pickerView selectedRowInComponent:0]];
	self.serviceURLLabel.text = initialServiceHost;
	self.serviceHost = initialServiceHost;


}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	NSLog(@"Size of the Scroll Region: Height = %0.2f, Width = %0.2f", 
		  self.scrollView.frame.size.height,
		  self.scrollView.frame.size.width
		);

	NSLog(@"The origin of the Scroll Region is: x = %0.2f, y = %0.2f",
		  self.scrollView.frame.origin.x,
		  self.scrollView.frame.origin.y
		);

	NSLog(@"Size of the UIPicker: Height = %0.2f, Width = %0.2f", 
		  self.pickerView.frame.size.height,
		  self.pickerView.frame.size.width
		);

	NSLog(@"The origin of the UIPicker is: x = %0.2f, y = %0.2f", 
		  self.pickerView.frame.origin.x,
		  self.pickerView.frame.origin.y
		);

    NSString *lastGoodUserName = [[NSUserDefaults standardUserDefaults] stringForKey:@"lastgoodusername"];
    if(lastGoodUserName) {
        self.usernameField.text = lastGoodUserName;
    }

    

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)loginPressed:(id)sender {

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

	NSLog(@"Attepting to log-in via service at [%@]", self.serviceHost);

    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString: self.serviceHost]];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"login" parameters:@{
                             @"username": self.usernameField.text,
                             @"password": self.passwordField.text
                             }];
    request.timeoutInterval = 10;
    
    
    [self configureServers:_pickerView];
    
    AFJSONRequestOperation *operation = 
	  [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSON) {

		  self.loginInProgress.hidden = YES;

		  if (JSON) {
			  if ([JSON objectForKey:@"merchant"]) {

				  // Let's see if we can pull out everything that we need
				  NSString *ticket = [JSON objectForKey:@"ticket"];
                  
                  // This is your credential for your service. We'll need it later for your server to give us an OAuth token
                  // if we don't have one already
                  [PPSPreferences setCurrentTicket:ticket];
                  
				  if (ticket == nil) {
					UIAlertView *alertView = 
					  [[UIAlertView alloc]
						  initWithTitle:@"Missing PayPal Login Info"
								message: @"Logging in to PayPal requires a non-nil ticket token, but OAuth returned a nil ticket."
							   delegate:nil
						cancelButtonTitle:@"OK"
						otherButtonTitles:nil];
											   
					[alertView show];

				  }
				  else {

					// We've got a ticket, we've got a merchant - next order of business 
					// is to tell the PayPalHereSDK to setActiveMerchant:
					self.merchant = [[PPHMerchantInfo alloc] init];
					
					// Now, you need to fill out the merchant info with the things you've gathered about the account on "your side"
					NSDictionary *yourMerchant = [JSON objectForKey:@"merchant"];
					self.merchant.invoiceContactInfo = [[PPHInvoiceContactInfo alloc]
													  initWithCountryCode: [yourMerchant objectForKey:@"country"]
													  city:[yourMerchant objectForKey:@"city"]
													  addressLineOne:[yourMerchant objectForKey:@"line1"]];
					self.merchant.invoiceContactInfo.businessName = [yourMerchant objectForKey:@"businessName"];
					self.merchant.invoiceContactInfo.state = [yourMerchant objectForKey:@"state"];
					self.merchant.invoiceContactInfo.postalCode = [yourMerchant objectForKey:@"postalCode"];
					self.merchant.currencyCode = [yourMerchant objectForKey:@"currency"];

                    if ([JSON objectForKey:@"access_token"]) {
						[self setActiveMerchantWithAccessTokenDict:JSON];
                      }
                    else {
                        [self loginToPayPal:ticket];
                    }
				  }
			  }
			  else {
				  self.merchant = nil;
				  UIAlertView *alertView = 
					  [[UIAlertView alloc]
						  initWithTitle:@"Heroku Login Failed"
								message:@"Check your Username and Password and try again."
							   delegate:nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil];
											   
				  [alertView show];

				  NSLog(@"Heroku login attempt failed.");
			  }
		  }
		  else {
			  UIAlertView *alertView = 
			  [[UIAlertView alloc]
						  initWithTitle:@"Heroku Login Failed"
								message: 
				  [NSString stringWithFormat: 
							  @"Server returned an ambiguous response (nil JSON dictionary). "
							@"Check your Username and Password and try again. "
							@"If problem continues, might be a good idea to see if the server is healthy [%@]",
							self.serviceHost]

							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil];
											   
			  [alertView show];

			  NSLog(@"Apparently logged into Heroku successfully - but we got a nil JSON dict");
		  }

		} failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {

		  self.loginInProgress.hidden = YES;

		  UIAlertView *alertView = 
		  [[UIAlertView alloc]
						  initWithTitle:@"Heroku Login Failed"
								message: 
			  [NSString stringWithFormat: @"The Server returned an error: [%@]",
						[error localizedDescription]]
							   delegate:nil
					  cancelButtonTitle:@"OK"
					  otherButtonTitles:nil];
											   
		  [alertView show];


		  NSLog(@"The Heroku login call failed: [%@]", error);

		}];
    
    [operation start];



}

- (void) setActiveMerchantWithAccessTokenDict:(NSDictionary *)JSON
{
	NSString* key = [PPSPreferences currentTicket];
	NSString* access_token = [JSON objectForKey:@"access_token"];
	NSString* access = [PPSCryptoUtils AES256Decrypt:access_token  withPassword:key];
                          
	if (key == nil || access == nil) {

        
		NSLog(@"Bailing because couldn't decrypt access_code.   key: %@   access: %@   access_token: %@", key, access, access_token);

		self.loginInProgress.hidden = YES;

		UIAlertView *alertView = 
			[[UIAlertView alloc]
				initWithTitle:@"Press the Login Button Again"
				message: @"Looks like something went wrong during the redirect.  Tap Login again to retry."
				delegate:nil
				cancelButtonTitle:@"OK"
				otherButtonTitles:nil];
											   
		[alertView show];


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
				[self transitionToTransactionViewController];
			}

			else {

				NSLog(@"We have FAILED to setActiveMerchant from setActiveMerchantWithAccessTokenDict, showing error Alert.");

				UIAlertView *alertView =
					[[UIAlertView alloc]
						initWithTitle:@"No PayPal Merchant Account"
						message:@"Can't attempt any transactions till you've set up a PayPal Merchant account!"
						delegate:nil
						cancelButtonTitle:@"OK"
						otherButtonTitles:nil];
											   
				[alertView show];

			}

		}];

}

- (void) loginToPayPal:(NSString *)ticket
{
  	NSLog(@"Logging in to PayPal...");
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString: self.serviceHost]];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"goPayPal" parameters:@{
                                                                                                       @"username": self.usernameField.text,
                                                                                                       @"ticket": ticket
                                                                                                       }];
    request.timeoutInterval = 10;
	
    AFJSONRequestOperation *operation =
    [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSON) {
        
        if (JSON) {
			NSLog(@"PayPal login attempt got some JSON back: [%@]", JSON);
            
			if ([JSON objectForKey:@"url"] && [[JSON objectForKey:@"url"] isKindOfClass:[NSString class]]) {
                
                // FIRE UP SAFARI TO LOGIN TO PAYPAL
                // \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_
                NSString *url = [JSON objectForKey:@"url"];
                NSLog(@"Pointing Safari at URL [%@]", url);
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
			}
			else {
                
                // UH-OH - NO URL FOR SAFARI TO FOLLOW, NO ACCESS TOKEN FOR YOU. FAIL.
                // \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ \_\_ 
                NSLog(@"FAILURE! Got neither a URL to point Safari to, nor an Access Token - WTF?");
                
                UIAlertView *alertView = 
				[[UIAlertView alloc]
                 initWithTitle:@"PayPal Login Failed"
                 message: @"Didn't get a URL to point Safari at, nor an Access Token - so we're screwed!"
                 delegate:nil
                 cancelButtonTitle:@"OK"
                 otherButtonTitles:nil];
                
                [alertView show];
                
			}
            
        }
        else {
			NSLog(@"PayPal login attempt got no JSON back!");
        }
        
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"The PayPal login attempt failed: [%@]", error);
        
    }];
    
    [operation start];
    
	NSLog(@"Attempting to login to Paypal as \"%@\" with ticket \"%@\"...", self.usernameField.text, ticket);
    
    
}

- (void)transitionToTransactionViewController
{
	STTransactionViewController *transactionVC = nil;
    
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
		transactionVC = [[STTransactionViewController alloc]
                         initWithNibName:@"STTransactionViewController_iPhone"
                         bundle:nil];
	}
	else {
		transactionVC = [[STTransactionViewController alloc]
                         initWithNibName:@"STTransactionViewController_iPad"
                         bundle:nil];
	}
    
	UIBarButtonItem *backButton = [[UIBarButtonItem alloc]
									  initWithTitle: @"Login"
									  style: UIBarButtonItemStyleBordered
									  target: nil 
									  action: nil];

	[self.navigationItem setBackBarButtonItem: backButton];
    

	[self.navigationController pushViewController:transactionVC animated:YES];
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


#pragma mark - UIPickerView

- (void)createPicker
{
  self.pickerViewArray = 
	  @[ 
		  @"Stage", 
		   @"Sandbox", 
		  @"Live"
		  ];

  self.pickerURLArray = 
	  @[ 
		  @"http://morning-tundra-8515.herokuapp.com", 
		   @"http://desolate-wave-3684.herokuapp.com", 
		  @"http://stormy-hollows-1584.herokuapp.com"
		  ];
    
  self.serviceArray =
    @[
       [NSURL URLWithString:@"https://www.stage2pph10.stage.paypal.com/webapps/"],
       [NSURL URLWithString:@"https://sandbox.paypal.com/webapps/"],
       [NSURL URLWithString:@"https://www.paypal.com/webapps/"]
    ];

  // note we are using CGRectZero for the dimensions of our picker view,                                                                   
  // this is because picker views have a built in optimum size,                                                                            
  // you just need to set the correct origin in your view.                                                                                 
  //                                                                                                                                       
  self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectZero];

  [self.pickerView sizeToFit];

  self.pickerView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

  self.pickerView.showsSelectionIndicator = YES;    // note this is defaulted to NO                                                      

  // this view controller is the data source and delegate                                                                                  
  self.pickerView.delegate = self;
  self.pickerView.dataSource = self;

  [self.scrollView addSubview:self.pickerView];
}

-(void)configureServers:(UIPickerView *)pickerView {
    NSLog(@"%@",
		  [NSString stringWithFormat:@"%@",
           [self.pickerViewArray objectAtIndex:[pickerView selectedRowInComponent:0]]]);
    
	NSString *serviceURL = [self.pickerURLArray objectAtIndex:[pickerView selectedRowInComponent:0]];
	self.serviceURLLabel.text = serviceURL;
	self.serviceHost = serviceURL;
    
    NSURL *urlForTheSDKToUse = [self.serviceArray objectAtIndex:[pickerView selectedRowInComponent:0]];
    NSLog(@"urlForTheSDKToUse: %@", urlForTheSDKToUse);
    [PayPalHereSDK setBaseAPIURL:urlForTheSDKToUse];
}

#pragma mark - UIPickerViewDelegate

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
	[self configureServers:pickerView];
}

#pragma mark - UIPickerViewDataSource

- (NSAttributedString *)pickerView:(UIPickerView *)pickerView attributedTitleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    NSMutableAttributedString *attrTitle = nil;

	NSString *title = [self.pickerViewArray objectAtIndex:row];
	attrTitle = [[NSMutableAttributedString alloc] initWithString:title];
	[attrTitle addAttribute:NSForegroundColorAttributeName
			   value:[UIColor blackColor]
			   range:NSMakeRange(0, [attrTitle length])];

	return attrTitle;

}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
	return [self.pickerViewArray objectAtIndex:row];
}

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component
{
	return self.pickerView.frame.size.width; // or 240.0?
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component
{
	return 40.0;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{   
    return [self.pickerViewArray count];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{   
    return 1;
}


@end
