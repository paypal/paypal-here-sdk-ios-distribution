//
//  PPSNeedPayPalSetupViewController.m
//  Here and There
//
//  Created by Metral, Max on 2/24/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <PayPalHereSDK/PayPalHereSDK.h>

#import "AFNetworking.h"
#import "PPSProgressView.h"
#import "UIView+NIStyleable.h"
#import "PPSNeedPayPalSetupViewController.h"
#import "PPSAlertView.h"
#import "PPSOrderEntryViewController.h"

@interface PPSNeedPayPalSetupViewController ()
{
    BOOL builtSubviews;
}
@property (strong,nonatomic) UILabel *detail;
@end

@implementation PPSNeedPayPalSetupViewController

-(void)goPayPal
{
    __block PPSProgressView *progress;
    
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString: sServiceHost]];
    httpClient.parameterEncoding = AFJSONParameterEncoding;
    NSURLRequest *request = [httpClient requestWithMethod:@"POST" path:@"goPayPal" parameters:@{
                             @"ticket": [PPSPreferences currentTicket],
                             @"username": [PPSPreferences currentUsername]
                             }];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSDictionary *JSON) {
        [progress dismiss:YES];
        if (JSON && [JSON objectForKey:@"url"] && [[JSON objectForKey:@"url"] isKindOfClass:[NSString class]]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[JSON objectForKey:@"url"]]];
        } else if (JSON && [JSON objectForKey:@"access_token"]) {
#ifdef oldway
            [PPSPreferences setMerchantFromServerResponse:JSON];
#else
            PPHMerchantInfo *merchantInfo = [PPSPreferences merchantFromServerResponse:JSON withMerchantId:[PPSPreferences currentUsername]];
            
            [PayPalHereSDK setActiveMerchant:merchantInfo withMerchantId:[PPSPreferences currentUsername] completionHandler:
              ^(PPHAccessResultType status, PPHAccessAccount *account, NSDictionary *extraInfo) {
                  //done;
                  NSLog(@"done");
              }];
#endif
            self.navigationController.viewControllers = @[[PPSOrderEntryViewController new]];
        } else {
            [PPSAlertView showAlertViewWithTitle:@"Oops" message:@"Failed to get a response from the Here and There server" buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
        }
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        [progress dismiss:YES];
        [PPSAlertView showAlertViewWithTitle:@"Oops" message:error.localizedDescription buttons:@[@"OK"] cancelButtonIndex:0 selectionHandler:nil];
    }];
    
    progress = [PPSProgressView progressViewWithTitle:@"Redirecting" andMessage:nil withCancelHandler:^(PPSProgressView *progressView) {
        [progress dismiss: YES];
        [operation cancel];
    }];
    [operation start];
    
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [NILocalizedStringWithDefault(@"PayPalAccess_SetupRequired", @"Link Your PayPal Account") attach:self withSelector:@selector(setTitle:)];
}

-(void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    if (!builtSubviews) {
        builtSubviews = YES;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"setupRequired" ofType:@"json" inDirectory:@"json/viewControllers/"];
        NSArray *viewSpecs = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:0 error:nil];
        
        self.dom.target = self;
        [self.view buildSubviews:viewSpecs inDOM:self.dom];
    } else {
        [self.dom refresh];
    }
}

-(NSString *)stylesheetName
{
    return @"setupRequired";
}

@end
