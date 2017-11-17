//
//  PPLocationManager.m
//

#import "PPLocationManager.h"

@interface PPLocationManager()

@property (nonatomic, strong) CLLocationManager* manager;
@property (nonatomic, strong) CLLocation *savedLocation;
@property (nonatomic, assign) BOOL usesSignificantTracking;
@property (nonatomic, assign) BOOL isWatching;

@end


@implementation CLLocationManager (PP)

+ (BOOL)hasAnyAuthorization {
    // I can't check for the actual enums because I don't want everyone that uses the SDK to compile against the iOS 8 SDK.
    return [CLLocationManager authorizationStatus] >= kCLAuthorizationStatusAuthorized;
}

@end

@implementation PPLocationManager

#pragma mark -
#pragma mark Initialization

+ (PPLocationManager *)sharedManager {
    static PPLocationManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[PPLocationManager alloc] init];
    });
    return shared;
}

- (id)init {
    if ((self = [super init])) {
        //If the CLLocationManager is initialized on a thread without a runloop, it will never supply locations. Hence, we use the main thread.
        [self performSelectorOnMainThread:@selector(initializeCLLocationManager) withObject:nil waitUntilDone:YES];
        self.usesSignificantTracking = [CLLocationManager significantLocationChangeMonitoringAvailable];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(awake) name: UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(asleep) name: UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver: self selector:@selector(asleep) name: UIApplicationWillTerminateNotification object: nil];
    }
    return self;
}

- (void)initializeCLLocationManager {
    self.manager = [[CLLocationManager alloc] init];
    self.manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers;
    self.manager.delegate = self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.manager.delegate = nil;
}

#pragma mark -
#pragma mark Interface Methods

- (BOOL)isPermittedToTransact {
    return [CLLocationManager locationServicesEnabled] && [CLLocationManager hasAnyAuthorization] && [self location];
}

- (void)startWatchingLocation {
    if (![CLLocationManager hasAnyAuthorization] && [self.manager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.manager performSelector:@selector(requestWhenInUseAuthorization)];
    }
    [self startLocationManagerUpdates];
    self.isWatching = YES;
}

- (void)stopWatchingLocation {
    if (self.isWatching) {
        [self stopLocationManagerUpdates];
        self.isWatching = NO;
    }
}

- (CLLocation *)location {
    CLLocation *loc = self.manager.location;
    
    if (loc) {
        // Update our saved location.
        if (!self.savedLocation || [loc.timestamp compare:self.savedLocation.timestamp] == NSOrderedDescending) {
            self.savedLocation = loc;
        }
    } else {
        loc = self.savedLocation;
    }
    
    return loc;
}

- (NSDictionary *)asDictionary {
    CLLocation *loc = [self location];
    
    return @{
             @"latitude": @(loc.coordinate.latitude).stringValue,
             @"longitude": @(loc.coordinate.longitude).stringValue
             };
}



#pragma mark -
#pragma mark CLLocationManagerDelegate Implementation

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    
}



#pragma mark -
#pragma mark NSNotificationCenter Callbacks

- (void)awake {
    if (self.isWatching) {
        [self startLocationManagerUpdates];
    }
}

- (void)asleep {
    [self stopLocationManagerUpdates];
}



#pragma mark -
#pragma mark Helper Methods

- (void)startLocationManagerUpdates {
    if (self.usesSignificantTracking) {
        [self.manager performSelectorOnMainThread:@selector(startMonitoringSignificantLocationChanges) withObject:nil waitUntilDone:YES];
    } else {
        [self.manager performSelectorOnMainThread:@selector(startUpdatingLocation) withObject:nil waitUntilDone:YES];
    }
}

- (void)stopLocationManagerUpdates {
    if (self.usesSignificantTracking) {
        [self.manager stopMonitoringSignificantLocationChanges];
    } else {
        [self.manager stopUpdatingLocation];
    }
}

@end
