//
//  PayPal Here
//
//  Copyright (c) 2012 PayPal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHInvoiceConstants.h"
#import "PPHPaymentConstants.h"
#import "PPHAmount.h"
#import "PPHCardNotPresentData.h"

/*!
 * A data structure representing a payment on an invoice. It includes details about the method of payment, any relevant transaction identifiers, the location
 * and other related information. There can be at most one payment against an invoice.
 */
@interface PPHInvoicePayment : NSObject

/*!
 * Create a payment record manually
 * @param transactionId the transaction identifier
 * @param amount the amount of hte payment
 * @param method the type of payment
 * @param detail additional data based on method
 * @param date the date of the payment
 */
-(id)initWithTransaction: (NSString*) transactionId forAmount: (PPHAmount*)amount withMethod: (PPHPaymentMethod) method andDetail: (PPHPaymentMethodDetail) detail onDate: (NSDate*)date;

/*!
 * Create a payment record from the server information
 * @param representation the server response as part of the invoice details
 */
-(id)initWithDictionary:(NSDictionary *)representation;
/*!
 * Render the payment information to a dictioary (mainly useful for local caching/storing)
 */
-(NSDictionary *)asDictionary;

/*! The high level method of payment */
@property (nonatomic,readonly) PPHPaymentMethod paymentMethod;

/*! Additional data related to the payment method, such as the source of the funds if known */
@property (nonatomic,readonly) PPHPaymentMethodDetail paymentMethodDetail;

/*! For PayPal balance-affecting transactions (cc, checkin) - the tx id of the payment */
@property (nonatomic,strong,readonly) NSString *transactionId;

/*! The amount of the payment or refund. */
@property (nonatomic,strong,readonly) PPHAmount *amount;

/*! The date on which the payment or refund occurred */
@property (nonatomic,strong,readonly) NSDate *date;

/*! Was the invoice paid on PayPal.com? */
@property (nonatomic,readonly) BOOL paidWithPayPal;

/*! The coordinates of the location where the payment was taken. */
@property (nonatomic,readonly) NSString* latitude;
/*! The coordinates of the location where the payment was taken. */
@property (nonatomic,readonly) NSString* longitude;

/*! Additional information about the payment such as the amount of cash tendered, etc. TODO put this in separate fields */
@property (strong,nonatomic,readonly) NSString* details;

/*! If this payment was made with a credit card this is the type of that card. */
@property (nonatomic,readonly) PPHCreditCardType creditCardType;

/*! If this payment was made with a credit card this is the last four digits of the card number. */
@property (strong,nonatomic,readonly) NSString* creditCardLastFourDigits;

/*! If this payment was made with a credit card this is the discrete application of that card that was used, if available. */
@property (strong,nonatomic,readonly) NSString* creditCardApplicationName;

/*! PayPal fee, if applicable and known - this is typically only filled out when reading payment details from transaction details APIs */
@property (strong,nonatomic,readonly) PPHAmount* fee;

/*! If this payment was made with cash and we know the amount tendered, this will be non-nil */
@property (strong,nonatomic,readonly) NSDecimalNumber *cashTendered;
@end
