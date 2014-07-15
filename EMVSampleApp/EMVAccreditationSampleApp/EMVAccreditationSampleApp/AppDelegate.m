//
//  AppDelegate.m
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import "AppDelegate.h"
#import "EMVOauthLoginViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        self.viewController = [[EMVOauthLoginViewController alloc] initWithNibName:@"EMVOauthLoginViewController_iPhone" bundle:nil];
    } else {
        self.viewController = [[EMVOauthLoginViewController alloc] initWithNibName:@"EMVOauthLoginViewController_iPad" bundle:nil];
    }
    
	self.navigationController = [[UINavigationController alloc] initWithRootViewController:self.viewController];
    self.window.rootViewController = self.navigationController;
    
	[self.window addSubview:self.navigationController.view];
    
    [self.window makeKeyAndVisible];
    
    [PayPalHereSDK askForLocationAccess];
    
    return YES;
}

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    
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
			[self.viewController isKindOfClass:[EMVOauthLoginViewController class]]) {
			[self.viewController setActiveMerchantWithAccessTokenDict:query];
		}
        
	}
	else {
		NSLog(@"%s url.host is NOT \"oauth\" so we're leaving without doing anything!", __FUNCTION__);
	}
    
	return YES;
    
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
