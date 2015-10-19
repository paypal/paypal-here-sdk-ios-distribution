//
//  AppDelegate.m
//  TakePayment
//
//  Copyright (c) 2015 PayPal Inc. All rights reserved.
//

#import "AppDelegate.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface AppDelegate ()

@property (nonatomic, strong) LoginViewController *loginVC;
@property (nonatomic, strong) PaymentViewController *paymentVC;

@end

@implementation AppDelegate

@synthesize window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [PayPalHereSDK askForLocationAccess];
    
    self.loginVC = [[LoginViewController alloc] init];
    self.paymentVC = [[PaymentViewController alloc] init];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:self.loginVC];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    [self.window setRootViewController:navVC];
    
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
