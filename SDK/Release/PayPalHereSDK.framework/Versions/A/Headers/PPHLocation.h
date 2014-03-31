//
//  PPHLocation.h
//  PayPalHereSDK
//
//  Created by Metral, Max on 1/2/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class PPHInvoiceContactInfo;
@class PPHError;

typedef NS_ENUM(NSInteger,PPHLocationCheckinType) {
    ePPHCheckinTypeNone = 0,
    ePPHCheckinTypeStandard
};

typedef NS_ENUM(NSInteger,PPHLocationCheckinExtensionType) {
    ePPHCheckinExtensionTypeNone = 0,
    ePPHCheckinExtensionTypePostOpen
};

typedef NS_ENUM(NSInteger,PPHLocationStatus) {
    ePPHLocationStatusUnknown = 0,
    ePPHLocationStatusActive = 1,
    ePPHLocationStatusDeleted = 2
};

typedef NS_ENUM(NSInteger,PPHGratuityType) {
    ePPHGratuityTypeNone = 0,
    ePPHGratuityTypeStandard = 1
};

/*!
 * A location represents a compartmentalized set of checkins for a merchant. A merchant may have
 * many locations, some of which are open at a particular time and able to accept new customer checkin.
 */
@interface PPHLocation : NSObject <
    NSCopying
>

/*!
 * Read a PPHLocation from the server
 * @param dictionary the server response
 */
-(id)initWithDictionary: (NSDictionary*)dictionary;

/*!
 * Save a PPHLocation to the server. If locationId is empty, this will create a new location
 * and the locationId parameter will become set.  Otherwise it will update an existing location.
 *
 * @param completionHandler called when the network request completes
 */
-(void)save: (void (^)(PPHError* error)) completionHandler;

/*!
 * Delete a PPHLocation.
 *
 * @param completionHandler called when the network request completes
 */
-(void)deleteLocation: (void (^)(PPHError *)) completionHandler;

/*!
 * The internal name of the location; this must be unique for the merchant
 */
@property (nonatomic,strong) NSString *internalName;

/*!
 * A short message displayed in search results
 */

@property (nonatomic,strong) NSString *displayMessage;
/*!
 * Not ALL fields of the contact info are used for locations. Line 1, Line 2, City, State,
 * PostalCode, Country, Phone Number and Business Name are used
 */
@property (nonatomic,strong) PPHInvoiceContactInfo *contactInfo;

/*!
 * Currently only latitude and longitude matter
 */
@property (nonatomic,assign) CLLocationCoordinate2D location;

/*!
 * Whether or not the location is open for checkins at the moment
 */
@property (nonatomic,assign) BOOL isAvailable;

/*!
 * Whether this location moves or always stays in the same place
 */
@property (nonatomic,assign) BOOL isMobile;

/*!
 * Whether checkins are supported at this location
 */
@property (nonatomic,assign) PPHLocationCheckinType checkinType;

/*!
 * The URL to use in conjunction with extension type
 ￼￼￼*/
@property (nonatomic,strong) NSURL* checkinExtensionUrl;
/*!
 * Checkin extensions allow the PayPal consumer application to do things after
 * a buyer checks in. As of this writing, the only extension available is
 * "postOpen" which basically means open a URL in a webview after checkin.
 * This enables a wide variety of features such as online ordering or
 * loyalty program integration
 */
@property (nonatomic,assign) PPHLocationCheckinExtensionType checkinExtensionType;

/*!
 * The URL for the logo image of this location
 */
@property (nonatomic,strong) NSString* logoUrl;

/*!
 * Length of time, in minutes, that an unused checkin lasts. A checkin expires after this duration,
 * or when the checkin is used in a payment—whichever occurs first. Minimum of 15. The default is 120.
 */
@property (nonatomic,assign) NSInteger checkinDurationInMinutes;

/*!
 * Whether the opportunity to set a tip should be shown to consumers in the PayPal app for this location
 */
@property (nonatomic,assign) PPHGratuityType gratuityType;

/*
 * These fields are supplied only by the PayPal server when the location has been read into the object
 */

/*!
 * An alphanumeric id for the location for use in other API calls
 */
@property (nonatomic,strong,readonly) NSString* locationId;
/*!
 * The date on which the location was originally created
 */
@property (nonatomic,strong,readonly) NSDate *createDate;
/*!
 * The date on which the location information was last updated
 */
@property (nonatomic,strong,readonly) NSDate *updateDate;
/*!
 * The current status of this location record (not the open/closed status the location itself - use isAvailable for that)
 */
@property (nonatomic,readonly) PPHLocationStatus status;
@end

#define kLocationNetworkActionCallID @"PPHLocation"

/*!
 * Errors fired in PPHError's associated with method calls to PPHLocation
 */
#define kPPHLocalErrorLocationIdNotSpecified -1000
