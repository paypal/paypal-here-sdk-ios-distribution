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
 * Return an invoice status given the non-localized string
 * @param string String representation of the invoice status
 */
+ (PPHInvoiceStatus)invoiceStatusFromString:(NSString*)string;

/*!
 * Turn an invoice status into a string
 * @param status the invoice status enumeration value
 */
+ (NSString*)stringFromInvoiceStatus:(PPHInvoiceStatus)status;

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
