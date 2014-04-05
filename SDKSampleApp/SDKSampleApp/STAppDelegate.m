//
//  STAppDelegate.m
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/14/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "STAppDelegate.h"

#import "STOauthLoginViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface STAppDelegate() <
PPHLoggingDelegate
>
@property (nonatomic,strong) id<PPHLoggingDelegate> sdkLogger;

@end

@implementation STAppDelegate

-(NSMutableArray *)transactionRecords
{
    if(!_transactionRecords) {
        _transactionRecords =  [[NSMutableArray alloc] init];
    }
    return _transactionRecords;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[STOauthLoginViewController alloc] initWithNibName:@"STOauthLoginViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[STOauthLoginViewController alloc] initWithNibName:@"STOauthLoginViewController_iPad" bundle:nil];
    }

	self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    self.window.rootViewController = self.navigationController;

	[self.window addSubview:self.navigationController.view];

    [self.window makeKeyAndVisible];

	NSLog(@"This is our Bundle Identifier Key: [%@]", [[[NSBundle mainBundle] infoDictionary] objectForKey:(NSString *)kCFBundleIdentifierKey]);

    
    // Let's setup the SDK ------------------------------
    
    /*
     * Default to using a stage.  The login sample UI will change this value.
     *
     *
     * Examples:
     *   To run against Live:
     *   [PayPalHereSDK setBaseAPIURL:nil];   OR don't call setBaseAPIURL at all.
     *
     *   To run against Sandbox:
     *   [PayPalHereSDK setBaseAPIURL:@"https://sandbox.paypal.com/webapps/"];
     *
     *   To run against a stage:
     *   [PayPalHereSDK setBaseAPIURL:[NSURL URLWithString:@"https://www.stage2pph10.stage.paypal.com/webapps/"]];
     */
    [PayPalHereSDK setBaseAPIURL:[NSURL URLWithString:@"https://www.stage2pph10.stage.paypal.com/webapps/"]];
   
    /* By default, the SDK has a remote logging facility for warnings and errors. This helps PayPal immensely in
     * diagnosing issues, but is obviously up to you as to whether you want to do remote logging, or perhaps you
     * have your own logging infrastructure. This sample app intercepts log messages and writes errors to the
     * remote logger but not warnings.
     */
    self.sdkLogger = [PayPalHereSDK loggingDelegate];
    [PayPalHereSDK setLoggingDelegate:self];
    
    /*
     * Let's tell the SDK who is referring these customers.
     * The referrer code is an important value which helps PayPal know which businesses and SDK
     * users are bringing customers into the PayPal system.  The referrer code is stored in the
     * invoices that are sent to the backend.
     */
    [PayPalHereSDK setReferrerCode:@"SDKSampleApp, Inc"];
    
    // Either the app, or the SDK must requrest location access if we'd like
    // the SDK to take payments.
    [PayPalHereSDK askForLocationAccess];
        
    return YES;
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{   
	if ([url.host isEqualToString:@"oauth"]) {
        
		NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
		for (NSString *keyValuePair in [url.query componentsSeparatedByString:@"&"]) {
			NSArray *pair = [keyValuePair componentsSeparatedByString:@"="];
			if (!(pair && [pair count] == 2)) continue;
            NSString *escapedData = [pair objectAtIndex:1];
            escapedData = [escapedData stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			[query setObject:escapedData forKey:[pair objectAtIndex:0]];
		}

		if ([query objectForKey:@"access_token"] && 
			[query objectForKey:@"expires_in"] && 
			[query objectForKey:@"refresh_url"] && 
			[self.viewController isKindOfClass:[STOauthLoginViewController class]]) {
			[self.viewController setActiveMerchantWithAccessTokenDict:query];
		}

	}
	else {
		NSLog(@"%s url.host is NOT \"oauth\" so we're leaving without doing anything!", __FUNCTION__);	
	}

	return YES;
}

// Let's intercept the logging messages of the SDK
// and display them so we can see what's happening.
//
#pragma mark PPHLoggingDelegate methods
-(void)logPayPalHereInfo:(NSString *)message {
    NSLog(@"%@", message);
}

-(void)logPayPalHereError:(NSString *)message {
    NSLog(@"%@", message);
    [self.sdkLogger logPayPalHereError: message];
}

-(void)logPayPalHereWarning:(NSString *)message {
    NSLog(@"%@", message);
}

-(void)logPayPalHereDebug:(NSString *)message {
    NSLog(@"Debug: %@", message);
}

-(void)logPayPalHereHardwareInfo:(NSString *)message {
    NSLog(@"Debug: %@", message);
}


@end
