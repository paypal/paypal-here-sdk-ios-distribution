//
//  PPHPaymentConstants.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 4/22/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPHCardEnums.h"

@class PPHAmount;

typedef NS_OPTIONS(NSInteger, PPHAvailablePaymentTypes) {
    ePPHAvailablePaymentTypeNone = 0,
    ePPHAvailablePaymentTypeCard = 1,
    ePPHAvailablePaymentTypeCheckin = 1 << 1,
    ePPHAvailablePaymentTypeChip = 1 << 2,
    ePPHAvailablePaymentTypeContactlessMSD = 1 << 3,
    ePPHAvailablePaymentTypeContactlessEMV = 1 << 4
};

typedef enum
{
    ePPHPaymentMethodUnknown = 0,
    ePPHPaymentMethodKey,
    ePPHPaymentMethodScan,
    ePPHPaymentMethodSwipe,
    ePPHPaymentMethodPaypal,
    ePPHPaymentMethodCheck,
    ePPHPaymentMethodCash,
    ePPHPaymentMethodChipCard,
    ePPHPaymentMethodEmvSwipe,
    ePPHPaymentMethodContactlessMSD,
    ePPHPaymentMethodContactlessEMV,
    ePPHPaymentMethodOther
} PPHPaymentMethod;

typedef enum
{
    ePPHPaymentMethodDetailNone = 0,
    ePPHPaymentMethodDetailBankTransfer = 5,
    ePPHPaymentMethodDetailDebitCard = 6,
    ePPHPaymentMethodDetailWireTransfer = 7,
} PPHPaymentMethodDetail;

typedef NS_ENUM(NSInteger, PPHTransactionStatus) {
    ePPHTransactionStatusPaid,
    ePPHTransactionStatusPaymentDeclined,
    ePPHTransactionStatusPaymentCancelled,
    ePPHTransactionStatusRefunded,
    ePPHTransactionStatusPartiallyRefunded,
    ePPHTransactionStatusRefundDeclined,
    ePPHTransactionStatusRefundCancelled
};

/*!
 * Convenience methods for dealing with payments
 * and their enumerations
 */
@interface PPHPaymentConstants : NSObject

/*!
 * Return a payment method given the corresponding non-localized string
 * @param string String representation of the payment method
 */
+ (PPHPaymentMethod)paymentMethodFromString:(NSString*)string;

/*!
 * Return payment method detail given the corresponding non-localized string
 * @param string String representation of the payment detail
 */
+ (PPHPaymentMethodDetail)paymentMethodDetailFromString:(NSString*)string;

/*!
 * Turn a payment method enum into a string
 * @param method the payment method enumeration value
 */
+ (NSString*)stringFromPaymentMethod:(PPHPaymentMethod)method;

/*!
 * Turn a payment method detail into a string
 * @param type the payment method detail enumeration value
 */
+ (NSString*)stringFromPaymentMethodDetail:(PPHPaymentMethodDetail)type;

/*!
 * Is the payment method a type of Contactless payment?
 * @param method the payment method
 */
+ (BOOL)paymentMethodIsContactless:(PPHPaymentMethod)method;

/*!
 * Check whether the payment method is a form of card present payment
 * @param method the payment method
 */
+ (BOOL)paymentMethodIsCardPresent:(PPHPaymentMethod)method;

/*!
 * Check whether the payment method is a form of EMV payments
 * @param method the payment method
 */
+ (BOOL)paymentMethodIsEmv:(PPHPaymentMethod)method;

/*!
 * Check whether the payment method is a swipe payment
 * @param method the payment method
 */
+ (BOOL)paymentMethodIsSwipe:(PPHPaymentMethod)method;

/*!
 * Check whether the payment method is a form of magstripe data.
 * @param method the payment method
 */
+ (BOOL)paymentMethodIsMSD:(PPHPaymentMethod)method;

/*!
 * Is the payment method a type of Credit Card payment?
 * @param method the payment method
 */
+ (BOOL)paymentMethodIsCreditCard:(PPHPaymentMethod)method;

/*!
 * Does the payment method put the invoice in a MarkedAsPaid state
 * (i.e. is it cash or check)
 * @param method the payment method
 */
+ (BOOL)paymentMethodMarksAsPaid:(PPHPaymentMethod)method;

/*!
 * Return a payment method given a contactless transaction type.
 * @param the contactless transaction type such as EMV or MSD.
 */
+ (PPHPaymentMethod)paymentMethodForContactlessTransactionType:(PPHContactlessTransactionType)type;

/*!
 * Do the given available payment types permit the given payment method
 * @param method the payment method to check permission for
 * @param availablePaymentTypes the mask of available payment types to test against
 */
+ (BOOL)paymentMethod:(PPHPaymentMethod)method isAllowedInAvailablePaymentTypes:(PPHAvailablePaymentTypes)availablePaymentTypes;

/*!
 * A non-user-friendly string identifier for the given transaction status
 */
+ (NSString*)stringFromTransactionStatus:(PPHTransactionStatus)transactionStatus;

/*!
 * Is the given transaction status related to a refund?
 */
+ (BOOL)transactionStatusIsRefund:(PPHTransactionStatus)transactionStatus;

/*!
 * Is the given transaction successful so far? Transactions being processed are in a successful state.
 */
+ (BOOL)transactionStatusIsSuccessful:(PPHTransactionStatus)transactionStatus;

/*!
 * Is the given transaction status related to a cancelled transaction?
 */
+ (BOOL)transactionStatusIsCancelled:(PPHTransactionStatus)transactionStatus;

/*!
 * Is the given transaction status related to a declined transaction?
 */
+ (BOOL)transactionStatusIsDeclined:(PPHTransactionStatus)transactionStatus;

@end
