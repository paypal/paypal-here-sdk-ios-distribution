//
//  PPSAppDelegate.h
//  Here and There
//
//  Created by Metral, Max on 2/21/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIStylesheetCache.h"
#import "PPSMasterViewController.h"

@interface PPSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NIStylesheetCache *stylesheetCache;
/**
 * In certain cases you may want to place "popover" UI such as card reader
 * status or custom alerts, location errors, etc. This master controller makes
 * it easy to do that without having to worry about device rotation and such because 
 * you can get things in front of your nav controller without going to the UIWindow
 * (which doesn't rotate its coordinate system).
 */
@property (strong, nonatomic) PPSMasterViewController *masterViewController;
+(PPSAppDelegate*)appDelegate;

@end
