//
//  PayPalHereSDK
//
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPHAmount;

typedef NS_ENUM(NSInteger,PPHLocationCheckinStatus)
{
    ePPHCheckinStatusUnknown = 0,
    ePPHCheckinStatusActive,
    ePPHCheckinStatusCancelled,
    ePPHCheckinStatusExpired,
    ePPHCheckinStatusPaid,
    ePPHCheckinStatusLeft,
    ePPHCheckinStatusDeleted
};

/*!
 * Details about a checkin created by a customer at a merchant location.
 */
@interface PPHLocationCheckin : NSObject

/*!
 * The server identifier for this checkin
 */
@property (nonatomic,strong,readonly) NSString *checkinId;

/*!
 * The ID for this customer; this ID is unique to your merchant account
 */
@property (nonatomic,strong,readonly) NSString *customerId;

/*!
 * The display name of this customer. Will not be their full name.
 */
@property (nonatomic,strong,readonly) NSString *customerName;

/*!
 * The date this checkin was created
 */
@property (nonatomic,strong,readonly) NSDate *createDate;

/*!
 * The date this checkin was last updated.
 */
@property (nonatomic,strong,readonly) NSDate *updateDate;

/*!
 * The date this checkin will expire.
 */
@property (nonatomic,strong,readonly) NSDate *expirationDate;

/*!
 * The buyer's photo for verification
 */
@property (nonatomic,strong,readonly) NSURL *photoUrl;

/*!
 * The status of the checkin
 */
@property (nonatomic,readonly) PPHLocationCheckinStatus status;

/*!
 * If the buyer has set a gratuity preference as a fixed amount, this value will be non-nil
 */
@property (nonatomic,strong) PPHAmount *gratuityAmount;
/*!
 * If the buyer has set a gratuity preference as a percentage, this value will be non-nil
 */
@property (nonatomic,strong) NSDecimalNumber *gratuityPercentage;
@end
