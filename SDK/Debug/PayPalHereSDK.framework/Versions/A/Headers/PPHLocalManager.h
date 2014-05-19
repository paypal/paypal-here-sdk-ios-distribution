//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <PayPalHereSDK/PPHLocationWatcher.h>
#import <PayPalHereSDK/PPHLocation.h>

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

/*!
 * Get or set the location for which a soft beacon should be advertised by this device, if the device supports BLE.
 * Use location watcher to get status of enablement
 */
@property (nonatomic, strong) PPHLocation *beaconLocation;

/*!
 * Whether the soft beacon is currently broadcasting (requires beaconLocation to be non-nil, but also that it's working.)
 * For status updates during the process, see PPHLocationWatcher.
 */
-(BOOL)isBeaconActive;

/*!
 * Using background beacon services requires specific entitlements for your application. Since we cannot read these entitlements
 * automatically at runtime, you must tell the SDK if you want background beacon advertisements to be enabled. Defaults to false.
 * Must be set before setBeaconLocation as it generally only matters when starting CoreBluetooth services.
 */
@property (nonatomic,assign) BOOL isBackgroundBeaconEnabled;
@end
