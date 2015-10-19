//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHPaymentConstants.h"

@class PPHPaymentLimits;

typedef NS_ENUM(NSInteger, PPHAccountStatus) {
    ePPHAccountStatusUnknown,
    ePPHAccountStatusReady,
    ePPHAccountStatusRestricted,
    ePPHAccountStatusEligible,
    ePPHAccountStatusIneligible
};

/*!
 * The PPHAccessUser class stores information about a successfully
 * authenticated PayPal Access account. Via the NSCoding protocol,
 * this object can be saved to persistent storage.
 *
 * PLEASE NOTE: The tokens in this object are sensitive information
 * giving the bearer the ability to perform operations against the
 * PayPal account, and must be treated accordingly (thus stored securely).
 * For simplicity, the PayPalHereSDK singleton has methods to do this
 * for you.
 */
@interface PPHAccessAccount : NSObject < NSCoding >

/*!
 * Initialize a PPHAccessAccount from details
 * @param accessToken the active access_token for this account
 * @param seconds the expiration time of the access token, in seconds from now
 * @param refreshUrl a URL on your application server which can generate a new access token
 * @param paypalAccessResponse if you requested extra data from PayPal Access (e.g. email address and such),
 *        pass it in paypalAccessResponse and we'll consume what we can and leave the rest in extraInfo
 */
-(id)initWithAccessToken: (NSString*) accessToken expires_in: (NSString*) seconds refreshUrl: (NSString*) refreshUrl details: (NSDictionary*) paypalAccessResponse;

/*!
 * YES if we have credentials available (e.g. access_token is non-nil)
 */
- (BOOL) hasCredentials;

/*!
 * The current access token for this account
 */
@property (nonatomic, strong, readonly) NSString *access_token;
/*!
 * The refresh URL which can be used to get a new access_token when it expires
 */
@property (nonatomic, strong, readonly) NSString *refresh_url;
/*!
 * The identifier for this account from the server, which can change 
 * if and when the PayPal Access process is repeated
 */
@property (nonatomic, strong, readonly) NSString *id_token;

/*!
 * The original scope requested for the token
 */
@property (nonatomic, strong, readonly) NSString *tokenScope;
/*!
 * The time the access token is expected to expire
 */
@property (nonatomic, strong, readonly) NSDate *accessTokenExpiration;

/*!
 * Whether the account is enabled for PayPal Here
 */
@property (nonatomic, assign, readonly) PPHAccountStatus status;

/*!
 * The PayPal ID for this account
 */
@property (nonatomic, strong, readonly) NSString *userId;
/*!
 * The primary email for this account
 */
@property (nonatomic, strong, readonly) NSString *email;
/*!
 * All known emails for the account
 */
@property (nonatomic, strong, readonly) NSArray *emails;
/*!
 * The type of payments this merchant account is allowed to accept using the SDK
 */
@property (nonatomic, readonly) PPHAvailablePaymentTypes availablePaymentTypes;
/*!
 * Information re payment limits
 */
@property (nonatomic, strong) PPHPaymentLimits *paymentLimits;
/*!
 * Any extra info provided by the OAuth process
 */
@property (nonatomic, strong, readonly) NSDictionary *extraInfo;
/*!
 * The default currency on the account, as specified in the /status method of the HereAPI.
 */
@property (nonatomic, strong, readonly) NSString *currencyCode;
@end

#define kPPHEmailAddressUnavailable 0xdeadbeef

