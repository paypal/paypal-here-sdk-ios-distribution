//
//  ViewController.m
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "LoginViewController.h"
#import "PPSPreferences.h"
#import "PPSCryptoUtils.h"
#import "PaymentViewController.h"

#define kLive @"Live"
#define kSandbox @"Sandbox"
#define kMock @"Mock"

#define kActionSheetTagMockCountrySelection 1
#define kActionSheetTagRepoSelection        2
#define kActionSheetTagStageSelection       3

#define kMockCountryAU @"AU"
#define kMockCountryUK @"UK"
#define kMockCountryUS @"US"

#define kStage2d0018 @"stage2d0018"
#define kStage2d0020 @"stage2d0020"
#define kStage2d0044 @"stage2d0044"
#define kStage2d0045 @"stage2d0045"
#define kStage2d0065 @"stage2d0065"
#define kStage2d0084 @"stage2d0084"
#define kStage2mb001 @"stage2mb001"
#define kStage2mb006 @"stage2mb006"
#define kStage2mb023 @"stage2mb023"
#define kStage2md044 @"stage2md044"
#define kStage2pph11 @"stage2pph11"
#define kStage2pph24 @"stage2pph24"
#define kStage2mb024 @"stage2mb024"
#define kStage2pph05 @"stage2pph05"
#define kStage2pph01 @"stage2pph01"
#define kStage2md030 @"stage2md030"
#define kStageOther @"Other"


#define kDevStage1 @"dev-stage-1"
#define kDevStage2 @"dev-stage-2"
#define kDevStage3 @"dev-stage-3"
#define kQaStage1 @"qa-stage-1"
#define kQaStage2 @"qa-stage-2"
#define kQaStage3 @"qa-stage-3"
#define kProdStage @"prod-stage"
#define kProd @"liveprod"

#define kSoftwareRepoArray @[kDevStage1, kDevStage2, kDevStage3, kQaStage1, kQaStage2, kQaStage3,kProdStage, kProd]
#define kStageNameArray @[kStage2d0018, kStage2d0020, kStage2d0044, kStage2d0045, kStage2d0065, kStage2d0084, kStage2mb001, kStage2mb006, kStage2mb023, kStage2md044, kStage2pph11, kStage2pph24, kStage2mb024, kStage2pph05, kStage2pph01, kStage2md030, kStageOther]
#define kMockCountryArray @[kMockCountryAU, kMockCountryUK, kMockCountryUS]

#define kMidTierServerUrl @"https://sdk-sample-server.herokuapp.com/server"

@interface LoginViewController ()
@property(nonatomic, strong) PPHMerchantInfo *merchant;
@property(nonatomic, strong) NSString *serviceHostUrl;
@property(nonatomic, strong) NSMutableString *urlForTheSdkToUse;
@property(nonatomic, strong) NSDictionary *sdkBaseUrlDict;

@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property(weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property(weak, nonatomic) IBOutlet UITextField *usernameField;
@property(weak, nonatomic) IBOutlet UITextField *passwordField;
@property (nonatomic, weak) IBOutlet UIButton *loginButton;
@property (nonatomic, strong) UIActionSheet *stageSelectedActionSheet;
@property (nonatomic, strong) UIActionSheet *mockCountryAccountActionSheet;
@property (nonatomic, strong) UIActionSheet *selectSoftwareRepoActionSheet;
@property (weak, nonatomic) IBOutlet UILabel *currentSoftwareRepo;
@property (weak, nonatomic) IBOutlet UILabel *currentStage;
@property (nonatomic, copy) NSString *activeServer;
@property (weak, nonatomic) IBOutlet UIButton *selectSoftwareRepoButton;

@property NSString *accessToken;
@property NSString *selectedEnvironemnt;


- (IBAction)onSoftwareRepoSelection:(id)sender;
- (IBAction)serviceHostSegmentedControlChanged:(id)sender;
- (IBAction)loginPressed:(id)sender;
- (IBAction)usernameFieldReturned:(id)sender;
- (IBAction)passwordFieldReturned:(id)sender;

- (void) setActiveMerchantWithAccessTokenDict:(NSDictionary *)JSON;

@end

@implementation LoginViewController

#pragma mark
#pragma mark - View Controller Setup and Tear Down Methods
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setUpSegmentedControlAndServiceUrls];
    [self setUpSpinnerAndTitle];
    [self setUpTextFields];
    [self stageSelectionActionSheet];
    [self softwareRepoSelectionActionSheet];
    [self createMockCountryAccountActionSheet];
    self.loginButton.layer.cornerRadius = 10;
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    //[self clearTextFields];
    [self loadRecentUserChoices];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setUpSegmentedControlAndServiceUrls {
    
    [self.segControl setSelectedSegmentIndex:UISegmentedControlNoSegment];
    self.serviceHostUrl = kMidTierServerUrl;
    self.sdkBaseUrlDict = [[NSMutableDictionary alloc] init];
    [self.sdkBaseUrlDict setValue:@"https://www.paypal.com/webapps/" forKey:kLive];
    [self.sdkBaseUrlDict setValue:@"https://www.sandbox.paypal.com/webapps/" forKey:kSandbox];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2d0018.stage.paypal.com/webapps/" forKey:kStage2d0018];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2d0020.stage.paypal.com/webapps/" forKey:kStage2d0020];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2d0044.stage.paypal.com/webapps/" forKey:kStage2d0044];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2d0045.stage.paypal.com/webapps/" forKey:kStage2d0045];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2d0065.stage.paypal.com/webapps/" forKey:kStage2d0065];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2d0084.stage.paypal.com/webapps/" forKey:kStage2d0084];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2mb006.stage.paypal.com/webapps/" forKey:kStage2mb001];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2mb006.stage.paypal.com/webapps/" forKey:kStage2mb006];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2mb023.stage.paypal.com/webapps/" forKey:kStage2mb023];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2md044.stage.paypal.com/webapps/" forKey:kStage2md044];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2pph11.stage.paypal.com/webapps/" forKey:kStage2pph11];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2pph24.stage.paypal.com/webapps/" forKey:kStage2pph24];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2mb024.stage.paypal.com/webapps/" forKey:kStage2mb024];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2pph05.stage.paypal.com/webapps/" forKey:kStage2pph05];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2pph01.stage.paypal.com/webapps/" forKey:kStage2pph01];
    [self.sdkBaseUrlDict setValue:@"https://www.stage2md030.stage.paypal.com/webapps/" forKey:kStage2md030];
    
}

-(void)createMockCountryAccountActionSheet {
    self.mockCountryAccountActionSheet = [[UIActionSheet alloc] initWithTitle:@"Mock country:"
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:kMockCountryAU, kMockCountryUK, kMockCountryUS, nil];
    self.mockCountryAccountActionSheet.tag = kActionSheetTagMockCountrySelection;
}

-(void)stageSelectionActionSheet {
    self.stageSelectedActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a stage:"
                                                                delegate:self
                                                       cancelButtonTitle:nil
                                                  destructiveButtonTitle:nil
                                                       otherButtonTitles:kStage2d0018, kStage2d0020, kStage2d0044, kStage2d0045, kStage2d0065, kStage2d0084, kStage2mb001, kStage2mb006, kStage2mb023, kStage2md044, kStage2pph11, kStage2pph24, kStage2mb024, kStage2pph05, kStage2pph01, kStage2md030, kStageOther, nil];
    self.stageSelectedActionSheet.tag = kActionSheetTagStageSelection;
}

-(void)softwareRepoSelectionActionSheet {
    self.selectSoftwareRepoActionSheet = [[UIActionSheet alloc] initWithTitle:@"Select a software repo:"
                                                                     delegate:self
                                                            cancelButtonTitle:nil
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles:kDevStage1, kDevStage2, kDevStage3, kQaStage1, kQaStage2, kQaStage3, kProdStage, kProd, nil];
    self.selectSoftwareRepoActionSheet.tag = kActionSheetTagRepoSelection;
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
    
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self resetTextFieldOffset];
    
    if (self.segControl.selectedSegmentIndex == 0) {
        self.activeServer = kLive;
        self.urlForTheSdkToUse = [self.sdkBaseUrlDict valueForKey:kLive];
        self.currentStage.text = @"Current Server: Live";
    }
    
    else if (self.segControl.selectedSegmentIndex == 1) {
        self.activeServer = kSandbox;
        self.urlForTheSdkToUse = [self.sdkBaseUrlDict valueForKey:kSandbox];
        self.currentStage.text = @"Current Server: Sandbox";
    } else if (self.segControl.selectedSegmentIndex == 3) {
        [self.mockCountryAccountActionSheet showInView:self.view];
    } else {
        [self.stageSelectedActionSheet showInView:self.view];
    }
    
    NSNumber *number = [NSNumber numberWithInt:(int)self.segControl.selectedSegmentIndex];
    [[NSUserDefaults standardUserDefaults] setObject:number forKey:@"liveSandboxOrStage"];             //Tell the SDK
    [[NSUserDefaults standardUserDefaults] setObject:self.activeServer forKey:@"activeServer"];
    
    
    NSLog(@"Service Host Url we will use for login %@", self.serviceHostUrl);
    NSLog(@"Url the PayPal Here SDK will be using: %@", self.urlForTheSdkToUse);
    
}

- (void)selectDevStageGivenIndex:(NSInteger)buttonIndex {
    self.currentSoftwareRepo.text = [@"Software Repo: " stringByAppendingString:kSoftwareRepoArray[buttonIndex]];
    [[NSUserDefaults standardUserDefaults] setObject:kSoftwareRepoArray[buttonIndex] forKey:@"deviceSoftwareRepo"];             //Tell the SDK
}

- (void)selectActiveServerGivenIndex:(NSInteger)buttonIndex {
    NSString *selectedStage = kStageNameArray[buttonIndex];
    if ([selectedStage isEqualToString:kStageOther]) {
        UIAlertController *enterStageNameAlert = [UIAlertController alertControllerWithTitle:nil message:@"Enter your stage name" preferredStyle:UIAlertControllerStyleAlert];
        [enterStageNameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = @"stage2d0083";
        }];
        [enterStageNameAlert addAction:[UIAlertAction actionWithTitle:@"Done" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *enteredStageName = [enterStageNameAlert.textFields[0] text];
            if (enteredStageName.length > 0 && ![enteredStageName isEqualToString:@""]) {
                [self setStageWithStageName:enteredStageName];
            }
        }]];
        [self presentViewController:enterStageNameAlert animated:YES completion:nil];
    } else {
        [self setStageWithStageName:kStageNameArray[buttonIndex]];
    }
}

- (void)setStageWithStageName:(NSString *)stageName  {
    self.activeServer = stageName;
    self.urlForTheSdkToUse = [NSMutableString stringWithFormat:@"https://www.%@.stage.paypal.com/webapps/", stageName];
    self.currentStage.text = [@"Current Server: " stringByAppendingString:stageName];
    self.selectedEnvironemnt = stageName;
    
    NSLog(@"Url the PayPal Here SDK will be using: %@", self.urlForTheSdkToUse);
}

- (void)selectMockCountryEnvironmentGivenIndex:(NSInteger)buttonIndex {
    self.activeServer = kMock;
    self.currentStage.text = @"Current Server: Mock";
    NSLog(@"Country we are mocking: %@", kMockCountryArray[buttonIndex]);
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (actionSheet.tag) {
        case kActionSheetTagRepoSelection: {
            [self selectDevStageGivenIndex:buttonIndex];
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:(int)buttonIndex] forKey:@"desiredDevStage"];
            break;
        }
        case kActionSheetTagStageSelection: {
            [self selectActiveServerGivenIndex:buttonIndex];
            NSNumber *stageIndex = [NSNumber numberWithInt:(int)buttonIndex];
            [[NSUserDefaults standardUserDefaults] setObject:stageIndex forKey:@"activeServerButtonIndex"];
            break;
        }
        case kActionSheetTagMockCountrySelection: {
            [self selectMockCountryEnvironmentGivenIndex:buttonIndex];
            break;
        }
    }
}


- (IBAction)loginPressed:(id)sender {
    
    if (self.segControl.selectedSegmentIndex != UISegmentedControlNoSegment && [self fieldValidation]) {
        
        [self.view endEditing:YES];
        [self resetTextFieldOffset];
        [self.spinner startAnimating];
        
        [self saveUserChoices];
        
        if ([self.activeServer isEqualToString:kMock]) {
            //if we are mocking the flows there is no need to perform any login
            NSString *accessToken = @"SDK_SIMULATOR_ACCESS_TOKEN_UK_ACCOUNT";
 
        } else {
        
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
        
        if(!response || !data) {
            [self showAlertWithTitle:@"Login failed." andMessage:@"We attempted to communicate PayPal's login servers, but their response contained no data"];
            [self.spinner stopAnimating];
            return;
        }
        
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

    self.accessToken = access;
    [self performSegueWithIdentifier:@"loginSuccess" sender:nil];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"loginSuccess"])
    {
        PaymentViewController *viewController = [segue destinationViewController];
        viewController.accessToken = [self createCompositeTokenWithAccessToken:self.accessToken andSelectedEnvironment:self.selectedEnvironemnt];
        NSLog(@"composite Token: %@", viewController.accessToken);
    }
}

-(NSString *)createCompositeTokenWithAccessToken:(NSString *) token andSelectedEnvironment:(NSString *)environment {
    
    NSArray *array = [NSArray arrayWithObjects:token, [NSNumber numberWithInt:28800], [NSNull new], @"L0WTzoVEL4Zw7GpHIYT6ZoxT4p3q2FgDXa5IgE6MkZ4MoCoTjbMjTQn8ByYWYwJiqDA19_m8O9B48qfaLE1c2DkQOjE3et2AQfjObYmOO2PYGvuYw_7pypjiJrI", @"SGVyZVNES1BPUzpIZXJlU0RLUE9T", nil];
    NSError *error;
    NSData * JSONData = [NSJSONSerialization dataWithJSONObject:array
                                                        options:kNilOptions
                                                          error:&error];
    
    NSString* compositeToken = [PPSCryptoUtils base64EncodedStringForData:JSONData];
    compositeToken = [NSString stringWithFormat:@"%@:%@", environment, compositeToken];

    return compositeToken;
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
    [loginRequestPostString appendString:self.activeServer];
    
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
    [loginRequestPostString appendString:self.activeServer];
    
    [loginRequest setHTTPBody:[loginRequestPostString dataUsingEncoding:NSUTF8StringEncoding]];
    
    return loginRequest;
    
}

#pragma mark
#pragma mark - Generic Helper methods
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
            [self.view setFrame:CGRectMake(0, -40, self.view.frame.size.width, self.view.frame.size.height)];
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


- (IBAction)onSoftwareRepoSelection:(id)sender {
    [self.selectSoftwareRepoActionSheet showInView:self.view];
}

- (void)saveUserChoices {
    [[NSUserDefaults standardUserDefaults] setObject:self.usernameField.text forKey:@"username"];
#ifdef DEBUG
    [[NSUserDefaults standardUserDefaults] setObject:self.passwordField.text forKey:@"password"];
#endif
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)loadRecentUserChoices {
    self.usernameField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
#ifdef DEBUG
    self.passwordField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
#endif
    
    NSNumber *devStageButtonIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"desiredDevStage"];
    [self selectDevStageGivenIndex:[devStageButtonIndex intValue]];
    
    NSNumber *stageButtonIndex = [[NSUserDefaults standardUserDefaults] objectForKey:@"activeServerButtonIndex"];
    [self selectActiveServerGivenIndex:[stageButtonIndex intValue]];
    
    NSNumber *liveSandboxOrStage = [[NSUserDefaults standardUserDefaults] objectForKey:@"liveSandboxOrStage"];
    self.segControl.selectedSegmentIndex = [liveSandboxOrStage intValue];
    
    switch(self.segControl.selectedSegmentIndex) {
        case 1:
            self.currentStage.text = @"Current Server: Sandbox";
            self.activeServer = kSandbox;
            break;
            
        case 3:
            self.currentStage.text = @"Current Server: Mock";
            self.activeServer = kMock;
            break;
            
        case 2:
            break;
            
        case 0:
        default:
            self.currentStage.text = @"Current Server: Live";
            self.activeServer = kLive;
            break;
    }
}

@end
