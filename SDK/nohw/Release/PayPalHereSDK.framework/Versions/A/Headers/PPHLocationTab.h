//
//  PayPalHereSDK
//
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,PPHLocationTabStatus)
{
    ePPHTabStatusUnknown = 0,
    ePPHTabStatusActive,
    ePPHTabStatusCancelled,
    ePPHTabStatusExpired,
    ePPHTabStatusPaid,
    ePPHTabStatusLeft,
    ePPHTabStatusDeleted
};

/*!
 * Details about a tab created by a customer at a merchant location.
 */
@interface PPHLocationTab : NSObject

/*!
 * The server identifier for this tab
 */
@property (nonatomic,strong,readonly) NSString *tabId;

/*!
 * The ID for this customer; this ID is unique to your merchant account
 */
@property (nonatomic,strong,readonly) NSString *customerId;

/*!
 * The display name of this customer. Will not be their full name.
 */
@property (nonatomic,strong,readonly) NSString *customerName;

/*!
 * The date this tab was created
 */
@property (nonatomic,strong,readonly) NSDate *createDate;

/*!
 * The date this tab was last updated.
 */
@property (nonatomic,strong,readonly) NSDate *updateDate;

/*!
 * The date this tab will expire.
 */
@property (nonatomic,strong,readonly) NSDate *expirationDate;

/*!
 * The buyer's photo for verification
 */
@property (nonatomic,strong,readonly) NSURL *photoUrl;

/*!
 * The status of the tab
 */
@property (nonatomic,readonly) PPHLocationTabStatus status;
@end
