//
//  PayPal Here
//
//  Copyright (c) 2012 PayPal, Inc. All rights reserved.
//

@class PPHInvoice;
@class PPMobileAPITransactionDetailsResult;
@class PPHError;

typedef void (^PPHInvoiceLoadDetailsCompletionHandler) (NSDictionary *invoiceData, PPHError *error);
typedef void (^PPHTransactionDetailsResultWrapper)(PPMobileAPITransactionDetailsResult *result);

typedef void (^PPHInvoiceBasicCompletionHandler) (PPHError *error);
typedef void (^PPHInvoiceLoadCompletionHandler) (PPHInvoice *invoice, PPHError *error);

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
    ePPHPaymentMethodOther
} PPHPaymentMethod;

typedef enum
{
    ePPHPaymentMethodDetailNone = 0,
    ePPHPaymentMethodDetailBankTransfer = 5,
    ePPHPaymentMethodDetailDebitCard = 6,
    ePPHPaymentMethodDetailWireTransfer = 7,
} PPHPaymentMethodDetail;

typedef enum
{
    ePPHInvoiceStatusUnknown = 0,
    ePPHInvoiceStatusDraft = 1,
    ePPHInvoiceStatusSent = 2,
    ePPHInvoiceStatusPaid = 3,
    ePPHInvoiceStatusMarkedAsPaid = 4,
    ePPHInvoiceStatusCanceled = 5,
    ePPHInvoiceStatusRefunded = 6,
    ePPHInvoiceStatusPartialRefund = 7,
    ePPHInvoiceStatusReversed = 8,
    ePPHInvoiceStatusPending = 9,
    ePPHInvoiceStatusSaved = 10,
    ePPHInvoiceStatusMarkedAsRefunded = 11,
} PPHInvoiceStatus;

#define kInvoiceNetworkActionCallID @"InvoiceNetworkAction"
#define kInvoiceHistoryRefreshCallID @"InvoiceHistoryRefresh"
#define kInvoiceRefundCallID @"Refund"
#define kInvoiceCCChargeCallId @"CardCharge"
#define kInvoiceCheckinChargeCallId @"CheckinCharge"
#define kInvoiceBarcodeChargeCallId @"CodePayment"
#define kInvoiceGetTransactionDetailsCallId @"TransactionDetails"
#define kInvoiceGetRefundDetailsCallId @"GetRefunds"

/*!
 * Convenience methods for dealing with the various invoice enumerations
 */
@interface PPHInvoiceConstants : NSObject

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
 * Return an invoice status given the non-localized string
 * @param string String representation of the invoice status
 */
+ (PPHInvoiceStatus)invoiceStatusFromString:(NSString*)string;

/*!
 * Turn a payment method enum into a string
 * @param method the payment method enumeration value
 */
+ (NSString*)stringFromPaymentMethod:(PPHPaymentMethod)method;
/*!
 * Turn an invoice status into a string
 * @param status the invoice status enumeration value
 */
+ (NSString*)stringFromInvoiceStatus:(PPHInvoiceStatus)status;
/*!
 * Turn a payment method detail into a string
 * @param type the payment method detail enumeration value
 */
+ (NSString*)stringFromPaymentMethodDetail:(PPHPaymentMethodDetail)type;


/*!
 * Is the payment method a type of Credit Card payment?
 * @param method the payment method
 */
+ (BOOL)paymentMethodIsCreditCard:(PPHPaymentMethod)method;
/*!
 * Determine whether this invoice status means that the invoice was paid at some point
 * (i.e. is it paid, refunded, or partially refunded)
 * @param status the invoice status
 */
+ (BOOL)invoiceStatusIsPaid:(PPHInvoiceStatus)status;
/*! Determine whether this invoice status means the invoice was refunded at some point
 * (i.e. refunded or partially refunded)
 * @param status the invoice status
 */
+ (BOOL)invoiceStatusIsRefunded:(PPHInvoiceStatus)status;
@end
