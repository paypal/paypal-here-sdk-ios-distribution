//
//  AppDelegate.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/16/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "AppDelegate.h"
#import "URLParser.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

- (BOOL)application:(UIApplication *)application openURL:(nonnull NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nonnull id)annotation {
    
    URLParser *parser = [[URLParser alloc] initWithURLString:url.absoluteString];
    // Gather the SdkCredential info from the sample server.
    NSString *accessToken = [parser valueForVariable:@"access_token"];
    NSString *refreshUrl = [parser valueForVariable:@"refresh_url"];
    NSString *environment = [parser valueForVariable:@"env"];
    
    // Save token to UserDefaults for further usage
    NSUserDefaults *tokenDefault =  [NSUserDefaults standardUserDefaults];
    [tokenDefault setValue:accessToken forKey:@"ACCESS_TOKEN"];
    [tokenDefault setValue:refreshUrl forKey:@"REFRESH_URL"];
    [tokenDefault setValue:environment forKey:@"ENVIRONMENT"];
    
    // Use the notification service to send the token to the InitializeViewController
    if ([sourceApplication isEqualToString:@"com.apple.SafariViewService"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"kCloseSafariViewControllerNotification" object:accessToken];
        return YES;
    }
    return YES;
}

@end
