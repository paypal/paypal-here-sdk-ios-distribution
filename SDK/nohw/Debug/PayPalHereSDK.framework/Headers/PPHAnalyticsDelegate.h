//
//  PayPalHereSDK
//
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kPPHAnalyticsEventNameKey         @"kPPHEventNameKey"
#define kPPHAnalyticsEventDescriptionKey  @"kPPHAnalyticsEventDescriptionKey"
#define kPPHAnalyticsEventErrorMessageKey @"kPPHAnalyticsEventErrorMessageKey"
#define kPPHAnalyticsEventSwiperTypeKey   @"kPPHAnalyticsEventSwiperTypeKey"

#define kPPHAnalyticsSwipeTypeRoam   @"kPPHAnalyticsSwipeTypeRoam"
#define kPPHAnalyticsSwipeTypeMagtek @"kPPHAnalyticsSwipeTypeMagtek"
#define kPPHAnalyticsSwipeTypeMagbar @"kPPHAnalyticsSwipeTypeMagbar"

#define kPPHAnalyticsSoftwareUpdateErrorTypeKey @"kPPHSoftwareUpdateErrorTypeKey"
#define kPPHAnalyticsSoftwareUpdateErrorKey     @"kPPHSoftwareUpdateErrorKey"
#define kPPHAnalyticsSoftwareUpdateErrorTypeNetwork  @"kPPHSoftwareUpdateErrorNetwork"
#define kPPHAnalyticsSoftwareUpdateErrorTypeDownload @"kPPHSoftwareUpdateErrorDownload"

typedef NS_ENUM(NSInteger, PPHAnalyticsEventType) {
    ePPHAnalyticsEventTypeNone = 0,
    /*! A "normal" event meant to help discern what features are being used in you're app, what situations are being encountered, etc. */
    ePPHAnalyticsEventTypeNormal = 1,
    /*! A "log" message that is not as useful for aggregation but more for individual session debugging and troubleshooting */
    ePPHAnalyticsEventTypeLog = 2,
};

typedef NS_ENUM(NSInteger, PPHAnalyticsEventName) {
    ePPHAnalyticsEvent_None = 0,
    ePPHAnalyticsEvent_ReaderInserted,
    ePPHAnalyticsEvent_ReaderRemoved,
    
    ePPHAnalyticsEvent_AudioSwiperError,
    ePPHAnalyticsEvent_AudioSwipeSuccessful,
    
    ePPHAnalyticsEvent_DockPortSwiperError,
    ePPHAnalyticsEvent_DockPortSwipeSuccessful,
    
    ePPHAnalyticsEvent_SoftwareUpdateError,
    ePPHAnalyticsEvent_SoftwareUpdateRestartReader
};

/*!
 * PPHAnalyticsDelegate is in charge of delivering analytics events to a server
 */
@protocol PPHAnalyticsDelegate <NSObject>
/*!
 * Start an analytics session - create any sort of visitor/device identifiers etc.
 * @param properties session-wide information about the session
 */
-(void)beginSession: (NSDictionary*) properties;

/*!
 * Update session information of an in progress session
 * @param properties session-wide information about the session
 */
-(void)amendSession: (NSDictionary*) properties;

/*!
 * End an analytics session - clear any identifiers
 */
-(void)endSession;
/*!
 * Log an analytics event
 * @param event the name of the event that has occurred
 * @param type the type of event that has occurred
 * @param info additional information about the event
 */
-(void)queueEvent: (PPHAnalyticsEventName) event withType: (PPHAnalyticsEventType) type andInfo: (NSDictionary*) info;
@end
