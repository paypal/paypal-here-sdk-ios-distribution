//
//  PPHPaymentLimits.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 8/13/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHAmount.h"

/*!
 * A container for various limits and rules around payments
 * consisting of useful properties and convenience methods
 */
@interface PPHPaymentLimits : NSObject

/*!
 * The smallest amount you can successfully charge with a card.  If nil then the value is unknown.
 */
@property (nonatomic, strong) NSDecimalNumber *minimumCardChargeAllowed;

/*!
 * The largest amount you can successfully charge with a card.  If nil then the value is unknown.
 */
@property (nonatomic, strong) NSDecimalNumber *maximumCardChargeAllowed;

/*!
 * Amount over which this merchant requires a signature.  If nil then the value is unknown.
 */
@property (nonatomic, strong) NSDecimalNumber *signatureRequiredAbove;

/*!
 * The largest amount at which you can successfully charge for a contactless payment (both 
 * card and on-device such as Apple Pay).
 */
@property (nonatomic, strong) NSDecimalNumber *contactlessTransactionLimit;

/*!
 * In the Auth-Capture use case, for a given merchant account, this method provides the
 * maximum allowed capture percentage for every authorization.
 *
 * The application/merchant can use this information to validate the capture amount entered on their
 * UI and throw a local error in case an invalid amount is being set.
 *
 * For example, if the value returned by this method is, lets say 120, if the merchant performs
 * an authorization for an invoice for an amount, lets say $100 then, while performing a capture,
 * the maximum amount that the merchant is allowed to capture would be $120 (120% of the original authorized amount).
 * If the merchant tries to capture more than the capture tolerance, it would result in an error sent by the PayPal
 * backend.
 *
 * NOTE: Currently applicable for US based merchants ONLY.
 */
@property (nonatomic, strong) NSDecimalNumber *captureTolerance;

@end
