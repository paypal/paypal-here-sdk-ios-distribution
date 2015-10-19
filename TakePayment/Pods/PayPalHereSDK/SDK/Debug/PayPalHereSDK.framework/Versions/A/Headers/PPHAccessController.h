//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHAccessAccount.h"
#import "PPHAccessResultType.h"

@class PPHError;

// ATTENTION - this interface will become private very soon.

typedef void (^PPHAccessTokenRefreshHandler)(PPHAccessResultType status, PPHError *error);
typedef void (^PPHAccessCompletionHandler)(PPHAccessResultType status, PPHAccessAccount* account, NSDictionary* extraInfo);

/*!
 * PPHAccessController helps you build OAuth authentication into your app. PLEASE NOTE:
 * In order to implement proper security, you should create a server similar to
 * the sample server included in this SDK to store your app secret server-side (only).
 *
 * If you have authentication other than PayPal Access to your server, use that to further
 * lock down who your server will give out access tokens to.
 */
@interface PPHAccessController : NSObject

/*!
 * Once you get an access_token and merchant info, pass it into setupMerchant
 * and we'll verify PayPal Here setup and save their credentials.
 *
 * DEPRECATED: Use the setActiveMerchant on PayPalHereSDK which now encompasses both telling us about the merchant
 * and setting them up.
 *
 * @param account The account created as a result of a successful PayPal Access login redirect
 * @param completionHandler Will be called when we have gotten information about the account (eligibility, identity)
 */
-(void)setupMerchant: (PPHAccessAccount*) account completionHandler: (PPHAccessCompletionHandler) completionHandler DEPRECATED_ATTRIBUTE;

/*!
 * Refresh a PPHAccessAccount token using the refresh_url. If successful, the access_token
 * will be updated
 * @param account the account for which the refresh_url should be used to get a new access_token
 * @param completionHandler called when refresh is complete
 */
-(void)refresh: (PPHAccessAccount*) account completionHandler: (PPHAccessTokenRefreshHandler) completionHandler;

@end

/*!
 * Used for network requests around OAuth (provided for cancellation purposes)
 */
#define kPPHOauthNetworkActivityKey @"PPH.OAuth"
