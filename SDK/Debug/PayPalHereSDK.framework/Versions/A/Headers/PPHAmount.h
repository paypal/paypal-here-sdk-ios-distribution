//
//  PPHAmount.h
//  PayPalHereSDK
//
//  Created by Max Metral on 10/31/12.
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * All money amounts in PayPal Here should use PPHAmount, as it encapsulates a currency and an appropriately precise amount.
 *
 * Helper methods perform common operations like rounding, formatting for display, etc.
 */
@interface PPHAmount : NSObject

/*!
 * Get the default currency code given an ISO country code
 * @param countryCode two letter ISO country code
 */
+(NSString*)defaultCurrencyCodeInCountry: (NSString*) countryCode;

/*!
 * Create a PPHAmount given a decimal and a currency
 * @param amount The amount in currency
 * @param currency The currency for the amount
 */
+(PPHAmount*)amountWithDecimal: (NSDecimalNumber*) amount inCurrency: (NSString*) currency;
/*!
 * Create a PPHAmount given a decimal in a string and a currency
 * @param stringValue The amount, as a string and not including currency symbol
 * @param currency The currency for the amount
 */
+(PPHAmount*)amountWithString: (NSString*) stringValue inCurrency: (NSString*) currency;

/*! Don't init PPHAmounts without data, consider them immutable */
-(id)init UNAVAILABLE_ATTRIBUTE;

/*!
 * Initialize an amount with the appropriate padding for a currency. For example,
 * in USD which is a 2 digit currency, passing 12345 will return 123.45
 * @param amount the amount with no decimal point
 * @param currency the currency for the amount
 */
-(id)initWithPadding: (NSString*) amount inCurrency: (NSString*) currency;
/*!
 * Initialize an amount and round to the appropriate precision for the currency.
 * For example in USD passing 1.232 would return 1.23
 * @param amount The amount, potentially with higher precision than the currency supports
 * @param currency the currency for the amount
 */
-(id)initWithRounding: (NSDecimalNumber*) amount inCurrency: (NSString*) currency;

/*!
 * The ISO currency code such as USD
 */
@property (nonatomic,strong,readonly) NSString *currencyCode;

/*!
 * The amount, with potentially higher precision than the currency supports
 * so that we don't break intermediate values.
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *amount;

/*! YES if the amount is valid (i.e. if amount is not NSDecimalNumber::notANumber */
-(BOOL) isValid;

/*! The amount in the minimal unit of the currency (e.g. penny in the US) */
-(NSInteger) amountInCents;

/*! The ISO currency NUMBER for the currency code */
-(NSInteger) isoCurrencyNumber;
/*! The currency symbol, such as $ for USD */
-(NSString*) currencySymbol;
/*! The amount of digits allowed after the decimal separator in this amount's currency */
-(NSUInteger)digitsAfterDecimalSeperator;

/*! The character use to separate the integer and fractional part of a decimal number */
- (NSString *)decimalSeparator;

/*! The amount as a string with a currency symbol included */
-(NSString*) stringValue;

/*! The amount as a string with no currency symbol */
-(NSString*) stringValueWithoutCurrencySymbol;

/*! The amount as a string with no currency symbol or thousands separators, and with the decimal 
 *  separator always set to "."
 */
-(NSString *)stringValueForPayment;

/*!
 * Multiply a PPHAmount by a decimal
 * @param multiple the amount to multiply by
 */
-(PPHAmount*) multiply: (NSDecimalNumber*) multiple;
/*!
 * Subtract a decimal from a PPHAmount
 * @param operand the amount to subtract from this PPHAmount
 */
-(PPHAmount*) subtract: (NSDecimalNumber*) operand;
/*!
 * Add a PPHAmount to a decimal
 * @param operand the amount to add
 */
-(PPHAmount*) add: (NSDecimalNumber*) operand;
/*!
 * Divide a PPHAmount by a decimal
 * @param divisor the amount to divide by
 */
-(PPHAmount*) divideBy: (NSDecimalNumber*) divisor;

/*!
 * Multiply two PPHAmounts
 * @param multiple the amount to multiply by
 */
-(PPHAmount*) multiplyByAmount: (PPHAmount*) multiple;
/*!
 * Subtract a PPHAmount from a PPHAmount
 * @param operand the amount to subtract from this PPHAmount
 */
-(PPHAmount*) subtractAmount: (PPHAmount*) operand;
/*!
 * Add two PPHAmounts
 * @param operand the amount to add
 */
-(PPHAmount*) addAmount: (PPHAmount*) operand;
/*!
 * Divide a PPHAmount by a PPHAmount
 * @param divisor the amount to divide by
 */
-(PPHAmount*) divideByAmount: (PPHAmount*) divisor;
/*!
 * Return a rounded amount
 */
-(PPHAmount*) roundedAmount;
@end
