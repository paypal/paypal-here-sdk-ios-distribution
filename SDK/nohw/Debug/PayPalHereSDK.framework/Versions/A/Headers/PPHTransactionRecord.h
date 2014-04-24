//
//  PPHTransactionRecord.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 8/13/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PPHInvoiceConstants.h"
#import "PPHCardSwipeData.h"

@class PPHShoppingCart;
@class PPHCardChargeResponse;

/*! A record of a completed transaction (purchast or refund)
 * Once a pyament is complete you are returned a PPHTransactionRecord.  Historical
 * lists of transacitons done last week are also represented this way.
 */
@interface PPHTransactionRecord : NSObject

/*! The invoice that was used for this purchase */
@property (nonatomic,strong,readonly) PPHInvoice *invoice;

/*! The date on which the payment or refund occurred */
@property (nonatomic,strong,readonly) NSDate *date;

/*! For PayPal balance-affecting transactions (cc, checkin) - the tx id of the payment */
@property (nonatomic,strong,readonly) NSString *transactionId;

@property (nonatomic,strong,readonly) NSString *payPalInvoiceId;

@property (nonatomic,strong,readonly) NSString *correlationId;

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

/*! Create a PPHTransactionRecord with a transactionId.  This can be used with beginRefund */
-(id) initWithTransactionId:(NSString *)transactionId;

/*! Create a PPHTransactionRecord with a transactionId and a payPalInvoiceId.  This can be used with sendReceipt */
-(id) initWithTransactionId:(NSString *)transactionId andWithPayPalInvoiceId:(NSString *)payPalInvoiceId;

@end
