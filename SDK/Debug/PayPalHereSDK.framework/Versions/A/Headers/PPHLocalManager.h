//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "PPHLocationWatcher.h"
#import "PPHLocation.h"

@class PPHError;

/*!
 * PPHLocalManager provides a "jumping off point" for manipulating merchant locations and watching open and closed checkins
 */
@interface PPHLocalManager : NSObject

/*!
 * Get an object that will notify delegate of new and removed checkins from customers
 * @param locationId the locationId of the merchant location as returned by the beginGetLocations method (or stored in
 * some preference based on a previous return of beginGetLocations)
 * @param delegate the object that will be notified when checkins are opened or closed. Note that at the moment you have
 * to call update: manually
 */
-(PPHLocationWatcher*)watcherForLocationId: (NSString*) locationId withDelegate: (id<PPHLocationWatcherDelegate>) delegate;

/*!
 * Kick off a request to get all merchant locations for the currently active merchant
 * @param handler called on completion of the request
 */
-(void)beginGetLocations: (void (^)(PPHError *error, NSArray* locations)) handler;


@end
