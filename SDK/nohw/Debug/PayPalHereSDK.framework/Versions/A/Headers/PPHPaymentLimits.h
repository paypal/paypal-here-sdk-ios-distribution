//
//  PPHPaymentLimits.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 8/13/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * A container for various limits and rules around payments
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

@end
