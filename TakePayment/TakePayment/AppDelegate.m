//
//  AppDelegate.m
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "LoginViewController.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface AppDelegate ()

@property (nonatomic, strong) LoginViewController *loginVC;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [PayPalHereSDK askForLocationAccess];
    
    self.loginVC = [[LoginViewController alloc] init];
    [self.window setRootViewController:self.loginVC];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    
    // Look for url scheme configured in the build settings and the one configured on the sample server, that would contain the secure token.
    if ([url.scheme isEqualToString:@"retailsdksampleapp"]) {
        NSString *token = url.query;
        [self.loginVC initializeSDKMerchantWithToken:token];
    }
    
    return  YES;
}

@end
