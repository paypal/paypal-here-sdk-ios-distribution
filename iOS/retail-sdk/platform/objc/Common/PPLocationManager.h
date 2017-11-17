//
//  PPLocationManager.h
//
#import "PPLocationManager.h"
#import <CoreLocation/CoreLocation.h>

@interface CLLocationManager(PP)
// iOS 8 introduces the Always and WhenInUse authorization types. The previous authorization value maps to Always
// but the SDK should only request WhenInUse, therefor we need to check for either value since they are both suitable
// for what we are using location for.
// Use this method to check for authorization rather than inspecting [CLLocationManager authorizationStatus] directly.
+ (BOOL)hasAnyAuthorization;

@end

@interface PPLocationManager : NSObject<CLLocationManagerDelegate>

+ (PPLocationManager*) sharedManager;

- (CLLocation *)location;

- (BOOL)isPermittedToTransact;

- (void)startWatchingLocation;

- (void)stopWatchingLocation;

- (NSDictionary*) asDictionary;

@end



