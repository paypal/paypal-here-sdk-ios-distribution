//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import "PPHAmount.h"

/*!
 * The minimal set of information required to take payment on an invoice
 */
@protocol PPHInvoiceProtocol <NSObject>
/*! The currency type used by this invoice */
-(NSString*) currency;

/*! The total amount due on the invoice */
-(PPHAmount*) totalAmount;

/*! The unique identifier for the invoice received when creating the invoice on the network */
-(NSString*) paypalInvoiceId;

/*!
 Compile the invoice's data to a format that is ready to save as an InvoiceType parameter to an API call.
 @return id The created invoice
 */
-(NSDictionary*) asDictionary;

/*! The buyer's email address if known. Often noreply@here.paypal.com */
-(NSString*) payerEmail;

@end
