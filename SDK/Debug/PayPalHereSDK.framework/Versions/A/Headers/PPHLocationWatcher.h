//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPHLocationCheckin;
@class PPHLocationWatcher;
@class PPHError;

/*! 
 * A PPHLocationWatcherDelegate receives events when new tabs are created, old tabs are removed,
 * and errors occur.
 */
@protocol PPHLocationWatcherDelegate <NSObject>
@optional
/*!
 * A new checkin has been opened since the last update
 * @param watcher information about the location on which the checkin has been opened
 * @param checkin information about the checkin and customer
 */
-(void)locationWatcher: (PPHLocationWatcher*) watcher didDetectNewTab: (PPHLocationCheckin*) checkin;
/*!
 * A checkin has been closed in some way (paid, cancelled, left, etc) since the last update
 * @param watcher information about the location on which the checkin has been closed
 * @param checkin last known information about the checkin and customer
 */
-(void)locationWatcher: (PPHLocationWatcher*) watcher didDetectRemovedTab: (PPHLocationCheckin*) checkin;
/*!
 * An error has occurred trying to update checkin information
 * @param watcher the watcher that tried to update
 * @param error the error
 */
-(void)locationWatcher: (PPHLocationWatcher*) watcher didReceiveError: (PPHError*) error;
/*!
 * A request for updated checkin information has completed successfully.
 * @param watcher the watcher that tried to update
 * @param openTabs Known open tabs as of the last update
 * @param wasModified Whether any checkin information was updated
 */
-(void)locationWatcher: (PPHLocationWatcher*) watcher didCompleteUpdate: (NSArray*) openTabs wasModified: (BOOL) wasModified;
@end

/*!
 * PPHLocationWatcher maintains a list of open tabs for a location and can update the list
 * when asked.
 */
@interface PPHLocationWatcher : NSObject
/*! The delegate to be notified of new and removed tabs, as well as update errors */
@property (nonatomic, unsafe_unretained) id<PPHLocationWatcherDelegate> delegate;

/*! The location id which this object watches */
@property (nonatomic, readonly, strong) NSString *locationId;
/*! Known open tabs as of the last update */
@property (nonatomic, readonly, strong) NSArray *openTabs;

/*!
 * Trigger an update against the server and dispatch events to the delegate as necessary.
 */
-(void)updateNow;

/*!
 * Trigger periodic updates. The watcher uses an adaptive strategy based on whether results are changing or not.
 * So for example, if it calls twice in the minimumUpdateInterval and the tabs have not changed, it will start towards
 * maximumUpdateIntervalSeconds. When results change, it will come back towards minimumUpdateIntervalSeconds.
 *
 * A good strategy is to call this method on your "order entry" page or main page with a reasonably high maximum interval
 * and then when you expect to be processing a payment, to call it again with lower values. Last caller wins. Also, update
 * will be called immediately upon this call.
 *
 * @param minimumUpdateIntervalSeconds After a successful call, wait at least this long until the next call
 * @param maximumUpdateIntervalSeconds After a successful call, wait no longer than this long until the next call
 */
-(void)updatePeriodically: (NSInteger) minimumUpdateIntervalSeconds withMaximumInterval: (NSInteger) maximumUpdateIntervalSeconds;

/*!
 * Stop any active periodic updates established with updatePeriodically:withMaximumInterval:
 */
-(void)stopPeriodicUpdates;
@end
