//
//  PPHTransactionRecord.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 8/13/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PPHInvoiceConstants.h"
#import "PPHPaymentConstants.h"
#import "PPHCardSwipeData.h"
#import "PPHReceiptDestination.h"

@class PPHTokenizedCustomerInformation;
@class PPHCardChargeResponse;

/*! The PPHTransactionRecord is an artifact of payment calls made to PayPal's backend - example of payment
 * calls include making a sale transaction, getting an authorization, capturing a previous authorization and
 * refunding a transaction. The exact details returned in each of these calls might be different but the Here
 * SDK abstracts this away so application developers can deal with these as opaque objects. Given a transaction
 * record the SDK can differentiate and tell whether it represents an authorization or a sale or a refund etc
 */
@interface PPHTransactionRecord : NSObject

/*! The invoice that was used for this purchase */
@property (nonatomic,strong,readonly) PPHInvoice *invoice;

/*! The date on which the payment or refund occurred */
@property (nonatomic,strong,readonly) NSDate *date;

/*! For PayPal balance-affecting transactions (cc, checkin) - the tx id of the payment.
 * In case of Auth and Capture, Holds the final capture id.
 */
@property (nonatomic,strong,readonly) NSString *transactionId;

/*! The authorization id of the payment. Only for AUTH & CAPTURE use case.*/
@property (nonatomic,strong,readonly) NSString *authorizationId;

@property (nonatomic,strong,readonly) NSString *payPalInvoiceId;

@property (nonatomic,strong,readonly) NSString *correlationId;

/*! CustomerId and receiptPreferences information used for sending a receipt */
@property (nonatomic,copy,readonly) NSString *customerId;

@property (nonatomic,copy,readonly) NSString *receiptPreferenceToken;

/*! Was the invoice paid on PayPal.com? */
@property (nonatomic,readonly) BOOL paidWithPayPal;

/*! The high level method of payment */
@property (nonatomic,readonly) PPHPaymentMethod paymentMethod;

/*! Additional data related to the payment method, such as the source of the funds if known */
@property (nonatomic,readonly) PPHPaymentMethodDetail paymentMethodDetail;

/*! The card that was used for this transaction (if applicable) */
@property (nonatomic,strong,readonly) PPHCardSwipeData* encryptedCardData;

/*! The Chip n Pin data sent to the reader (if applicable) */
@property (nonatomic,strong,readonly) NSString *authCode;

/*! The Chip n Pin transaction handle (if applicable) */
@property (nonatomic,strong,readonly) NSString *transactionHandle;

/*! Customer info associated to the given payment (if applicable) */
@property (nonatomic,strong,readonly) PPHTokenizedCustomerInformation *customerInfo;

/*! The destination we sent a receipt to if one was sent and the destination was manually entered */
@property (nonatomic,strong,readonly) PPHReceiptDestination *receiptDestination;

/*! The last known status associated with this transaction */
@property (nonatomic,readonly) PPHTransactionStatus transactionStatus;

/*! Create a PPHTransactionRecord with a transactionId.  This can be used with beginRefund */
-(id) initWithTransactionId:(NSString *)transactionId;

/*! Create a PPHTransactionRecord with a transactionId and a payPalInvoiceId.  This can be used with sendReceipt */
-(id) initWithTransactionId:(NSString *)transactionId andWithPayPalInvoiceId:(NSString *)payPalInvoiceId;

/*! Create a PPHTransactionRecord with an authorization id and an invoice. This would mainly be used in case of the auth-capture flow.
 * Upon a successful auth, the corresponding transaction record would contain an authorizationId along with other details such as invoice,
 * card information, etc. The application could choose to just save the authorizationId and the invoiceId.
 * In order to perform a capture, this API could be used in conjuction with the "downloadInvoiceForInvoiceId" API to recreate the transaction record.
 */
-(id) initWithAuthorizationId:(NSString *)authorizationId andWithInvoice:(PPHInvoice *)invoice;

/*! Create a PPHTransactionRecord with an invoice.  This can be used with beginRefund */
-(id) initWithInvoice:(PPHInvoice *)invoice;

@end
