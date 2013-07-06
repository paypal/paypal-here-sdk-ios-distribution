//
//  PPSAppDelegate.m
//  Here and There
//
//  Created by Metral, Max on 2/21/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSAppDelegate.h"
#import "NIChameleonObserver.h"
#import "PPSLoginViewController.h"
#import "PPSMasterViewController.h"
#import "PPSCryptoUtils.h"
#import "NSString+NimbusCore.h"
#import "PPSOrderEntryViewController.h"
#import "PPSProgressView.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface PPSAppDelegate () <
    PPHNetworkRequestDelegate,
    PPHLoggingDelegate
>
@property (nonatomic,strong) NIChameleonObserver *chameleonObserver;
@property (nonatomic,strong) id<PPHLoggingDelegate> sdkLogger;
@end

@implementation PPSAppDelegate
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

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#ifdef DEBUG
    // If you're in staging... use this.
    // IMPORTANT: you may need to install the intermediate certificate on your device by visiting:
    // https://www.digicert.com/CACerts/DigiCertHighAssuranceCA-3.crt
    // which I've shortened to http://tiny.cc/pphstageca
    [PayPalHereSDK setBaseAPIURL:[NSURL URLWithString:@"https://www.stage2md030.stage.paypal.com/webapps/"]];
    [PayPalHereSDK setNetworkDelegate:self];
    
    // By default, the SDK has a remote logging facility for warnings and errors. This helps PayPal immensely in
    // diagnosing issues, but is obviously up to you as to whether you want to do remote logging, or perhaps you
    // have your own logging infrastructure. This sample app intercepts log messages and writes errors to the
    // remote logger but not warnings.
    self.sdkLogger = [PayPalHereSDK loggingDelegate];
    [PayPalHereSDK setLoggingDelegate:self];
#endif
    [self setupNimbusCss];
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    PPSLoginViewController *root = [[PPSLoginViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:root];
    
    self.masterViewController = [[PPSMasterViewController alloc] initWithViewController:nav];
    self.window.rootViewController = self.masterViewController;
    
    [self.window makeKeyAndVisible];
    return YES;
}

#ifdef DEBUG
-(BOOL)beginRequest:(NSMutableURLRequest *)inRequest withID:(NSString *)identifier withHandler:(void (^)(NSHTTPURLResponse *, NSError *, NSData *))handler
{
    // In debug mode, print network requests
    NSLog(@"%@ Request to %@\n%@", inRequest.HTTPMethod, inRequest.URL, inRequest.HTTPBody ? [[NSString alloc] initWithData:inRequest.HTTPBody encoding:NSUTF8StringEncoding] : @"");
    return NO;
}

-(void)requestCompleted:(NSURLRequest *)inRequest withResponse:(NSHTTPURLResponse *)inResponse data:(NSData *)data andError:(NSError *)error
{
    NSLog(@"%@ Response from %@\nError: %@\n%@", inRequest.HTTPMethod, inRequest.URL, error, [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}
#endif

-(void)setupNimbusCss
{
    NSString* pathPrefix = NIPathForBundleResource(nil, @"");
    _stylesheetCache = [[NIStylesheetCache alloc] initWithPathPrefix:pathPrefix];
    
#ifdef DEBUG
    _chameleonObserver = [[NIChameleonObserver alloc] initWithStylesheetCache:_stylesheetCache
                                                                         host:nil];
    [_chameleonObserver enableBonjourDiscovery: CHAMELEON_HOST];
#endif
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if ([url.host isEqualToString:@"oauth"]) {
        NSDictionary *allValues = [url.query queryContentsUsingEncoding:NSUTF8StringEncoding];
        NSMutableDictionary *query = [[NSMutableDictionary alloc] init];
        [allValues enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSArray *vals, BOOL *stop) {
            if (vals && vals.count) {
                [query setValue:[vals objectAtIndex:0] forKey:key];
            }
        }];
        
        NSString *access_arg = [query objectForKey:@"access_token"], *refresh = [query objectForKey:@"refresh_url"];
        
        if (access_arg && refresh) {
            NSString* key = [PPSPreferences currentTicket];
            NSString* access = [PPSCryptoUtils AES256Decrypt: access_arg withPassword:key];
            
            if (access && refresh) {
                PPHAccessAccount *account = [[PPHAccessAccount alloc] initWithAccessToken:access expires_in:[query objectForKey:@"expires_in"] refreshUrl:refresh details:query];
                PPHMerchantInfo *merchant = [PayPalHereSDK activeMerchant];
                merchant.payPalAccount = account;
                PPHAccessController *c = [[PPHAccessController alloc] init];
                PPSProgressView *progress = [PPSProgressView progressViewWithTitle:@"Linking Accounts" andMessage:nil withCancelHandler:nil];
                [c setupMerchant:account completionHandler:^(PPHAccessResultType status, PPHAccessAccount *transaction, NSDictionary *extraInfo) {
                    [progress dismiss:YES];
                    
                    [PayPalHereSDK setActiveMerchant:merchant asDefaultMerchant:YES];
                    UINavigationController *nc = (UINavigationController*) self.masterViewController.mainController;
                    nc.viewControllers = @[[PPSOrderEntryViewController new]];
                    NSLog(@"%@",account);
                }];
            }
        }
    }
    
    return YES;
}

+(PPSAppDelegate *)appDelegate
{
    return (PPSAppDelegate*) [UIApplication sharedApplication].delegate;
}
@end
