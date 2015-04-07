//
//  STAppDelegate.h
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/14/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "PayPalHereSDK.h"


@class STOauthLoginViewController;

@interface STAppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) STOauthLoginViewController *viewController;

@property (strong, nonatomic) CLLocationManager *localMgr;
@property (assign, nonatomic) BOOL isMerchantCheckedin;
@property (strong, nonatomic) PPHLocation *merchantLocation;
@property (strong, nonatomic) NSMutableArray *refundableRecords;
@property (strong, nonatomic) NSMutableArray *authorizedRecords;
@property (assign, nonatomic) BOOL paymentFlowIsAuthOnly;
@property (strong, nonatomic) NSDecimalNumber *captureTolerance;
@property (copy, nonatomic) NSString *serviceURL;
@property (copy, nonatomic) NSString *selectedStage;

@end
