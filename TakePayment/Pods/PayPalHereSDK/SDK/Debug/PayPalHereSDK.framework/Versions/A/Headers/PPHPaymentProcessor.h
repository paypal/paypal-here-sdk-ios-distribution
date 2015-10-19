//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHInvoiceProtocol.h"
#import "PPHCardNotPresentData.h"
#import "PPHInvoiceConstants.h"
#import "PPHReceiptDestination.h"
#import "PPHTransactionRecord.h"

/*!
 * All network requests around payment will use this id (which can be passed to the network delegate to cancel them)
 */
#define kPPHPaymentNetworkRequestId @"PPHPayment"

@class PPHTokenizedCustomerInformation;
@class PPHChipAndPinAuthEvent;
@class PPHChipAndPinEventWithEmv;
@class PPHLocationCheckin;
@class PPHCardSwipeData;
@class PPHError;
@class UIImage;

/*!
 * Generic base class for payment attempt response data from PayPal services
 */
@interface PPHPaymentResponse : NSObject
/*!
 * Non-nil if an error has occurred in processing the payment.
 */
@property (nonatomic,strong) PPHError* error;
/*!
 * Non-nil if the transaction has succeeded and has a reference number.
 * For the auth and capture use case, this would house the final capture Id as well.
 */
@property (nonatomic,strong) NSString* transactionId;

/*!
 * Non-nil if the authorization has succeeded and has a reference number.
 */
@property (nonatomic,strong) NSString* authorizationId;

/*!
 * The invoiceId of the invoice this payment was made against.
 */
@property (nonatomic,strong) NSString* paypalInvoiceId;
/*!
 * The correlation ID of the transaction attempt.
 */
@property (nonatomic,strong) NSString* correlationId;

/*!
 * Whether this was an authorization rather than a sale. In this context,
 * authorization means a "complete transaction and verification of funds"
 * that provides a token that can be captured at a future time. Note that
 * this is NOT the same as an "EMV authorization" which is a part of the
 * transaction flow for EMV.
 */
@property (nonatomic,assign) BOOL isPaymentAuthorization;
/*!
 * Return this object as a dictionary (for example for JSON serialization)
 */
- (NSDictionary *) asDictionary;
/*!
 * Create a payment response from an NSDictionary that was generated with asDictionary
 * @param dictionary : dictionary to be converted to a payment response object.
 */
- (id) initWithDictionary: (NSDictionary *) dictionary;
@end

/*!
 * Additional response data for chip&pin payment attempts
 */
@interface PPHChipAndPinAuthResponse : PPHPaymentResponse
/*!
 * Data to be sent to the terminal.
 */
@property (nonatomic,strong) NSString* authCode;
/*!
 * An identifier for this "leg" of the transaction
 */
@property (nonatomic,strong) NSString* transactionHandle;
/*!
 * Non-fatal warnings about the transaction attempt
 */
@property (nonatomic,strong) NSArray*  warnings;
/*!
 * Processor response code.
 */
@property (nonatomic,strong) NSString* responseCode;
@end


/*!
 * Additional response data for refund eligibility requests
 */
@interface PPHRefundEligibilityResponse : PPHPaymentResponse
/*!
 * True if the card was eligible for a refund
 */
@property (nonatomic, assign) BOOL isEligible;
@end

/*!
 * For future capability around specific card processing information (as opposed to tabs, for example)
 */
@interface PPHCardChargeResponse : PPHPaymentResponse
/**
 * Information unique to the presented card information which enables pre-configured receipt destination or loyalty programs.
 */
@property (nonatomic, strong) PPHTokenizedCustomerInformation *customer;
@end

/*!
 * The PPHPaymentProcessor is your one stop shop for turning various events into real money movement for your merchants.
 * It supports card swipes, manually entered card data, chip and pin, and checkin/tab based transactions.
 */
@interface PPHPaymentProcessor : NSObject

/*!
 * Issue a refund against a previously successful PayPal transaction.
 * @param transactionId The transaction identifier for the original payment transaction
 * @param amountOrNil Only pass an amount in the case of a partial refund. Otherwise, the backend will ensure it's a full refund.
 * @param completionHandler called when the action has completed
 */
- (void)beginRefund: (NSString*) transactionId forAmount: (PPHAmount*) amountOrNil completionHandler: (void(^)(PPHPaymentResponse*)) completionHandler;

/*!
 * Issue a refund against a previously successful non-PayPal transaction.
 * @param invoiceId The identifier for the invoice to be refunded.
 * @param amountOrNil Only pass an amount in the case of a partial refund. Otherwise, the backend will ensure it's a full refund.
 * @param completionHandler called when the action has completed
 */
-(void)beginNonPayPalRefundWithInvoiceId: (NSString *) invoiceId forAmount: (PPHAmount *) amountOrNil completionHandler: (void (^)(PPHPaymentResponse *)) completionHandler;


#pragma mark - Local/Tab payment
/*!
 * Capture funds against an open checkin from PPHLocalManager and PPHLocationWatcher
 * @param checkin information about the checkin (only id is needed)
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)beginCheckinPayment: (PPHLocationCheckin*) checkin forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^)(PPHPaymentResponse*)) completionHandler;

#pragma mark - Card related payment options

/*!
 * Collect funds against a card that has been passed through a reader and for which magstripe data is available.
 * @param card from PPCardReaderManager swipe event
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 * @param signature the buyer-generated signature, or nil for no signature. If signature is nil, a signature should be provided later
 * with provideSignature:forTransaction:andInvoice:completionHandler:
 */
-(void)beginCardPresentChargeAttempt: (PPHCardSwipeData*) card forInvoice: (id<PPHInvoiceProtocol>) invoice withSignature: (UIImage*) signature completionHandler: (void (^)(PPHCardChargeResponse *response)) completionHandler;

/*!
 * Authorize funds against a card that has been passed through a reader and for which magstripe data is available.
 * @param card from PPCardReaderManager swipe event
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 * with provideSignature:forTransaction:andInvoice:completionHandler:
 */
-(void)beginCardPresentAuthorizationAttempt: (PPHCardSwipeData*) card forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^)(PPHCardChargeResponse *response)) completionHandler;

/*!
 * Collect funds against a card that has been manually entered.
 * @param card Filled out manually or via a Card Scan
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)beginCardNotPresentChargeAttempt: (PPHCardNotPresentData*) card forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^) (PPHCardChargeResponse *response)) completionHandler;

/*!
 * Authorize funds against a card that has been passed in via manual entry, or user key-in.
 * @param card for PPHCardNotPresentData passed in manual card data
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)beginCardNotPresentAuthorizationAttempt:(PPHCardNotPresentData *)card forInvoice:(id<PPHInvoiceProtocol>)invoice
    completionHandler:(void (^)(PPHCardChargeResponse *))completionHandler;

/*!
 * Capture funds against an authorization.
 * @param txId : The authorization id obtained after a successful authorization.
 * @param amount : Amount to be captured.
 * @param invoice : The invoice against which the auth was performed.
 * @param finalCapture : Set to YES if its a final capture. NO, if we would like to perform multiple captures against this auth. Currently, the SDK supports ONLY single captures.
 * @param completionHandler : Called when the action has completed.
 */
-(void)beginCaptureForTransactionId:(NSString *)txId withAmount:(PPHAmount *)amount andInvoice:(id<PPHInvoiceProtocol>)invoice asFinal:(BOOL)finalCapture withCompletionHandler:(void (^)(PPHCardChargeResponse *))completionHandler;

/*!
 * Void an existing authorization.
 * @param txId : The authorization id obtained after a successful authorization.
 * @param invoice : The invoice against which the auth was performed.
 * @param completionHandler : Called when the action has completed.
 */
-(void)beginVoidForTransactionId:(NSString *)txId withInvoice:(id<PPHInvoiceProtocol>)invoice andCompletionHandler:(void (^)(PPHCardChargeResponse *))completionHandler;

/*!
 * Mark an invoice as having been paid by an external payment type such as Cash or Check.
 * @param paymentType must be cash or check currently for this method to succeed
 * @param note a short note, such as the amount tendered or check number
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)beginRecordingExternalPayment: (PPHPaymentMethod) paymentType withNote: (NSString*) note forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^) (PPHPaymentResponse *response)) completionHandler;

/*!
 * Provide a signature record for a previously successful charge.
 * @param signature the buyer-generated signature
 * @param response the result of beginCardPresentChargeAttempt
 * @param invoice the invoice of the transaction that's being signed for
 * @param completionHandler called when the action has completed
 */
-(void)provideSignature: (UIImage *)signature forTransaction: (PPHCardChargeResponse *)response andInvoice: (id<PPHInvoiceProtocol>)invoice completionHandler: (void (^)(PPHError *))completionHandler;



#pragma mark - Refund Eligibility

/*!
 * Check if the given swipe card data was the same card used to pay the transaction
 * @param card the card data to be checked
 * @param record the transaction record against which to check the card
 * @param completionHandler handler to call when the action has completed
 */
-(void)checkRefundEligibilityForCardPresent:(PPHCardSwipeData*)card
                          transactionRecord:(PPHTransactionRecord *)record
                          completionHandler:(void(^)(PPHRefundEligibilityResponse*))completionHandler;



#pragma mark - Receipts
/*!
 * Send the receipt for a particular transaction or transaction attempt/failure to an email address or mobile phone number.
 * @param payment the response from the server for the payment attempt. In the case of successful non-EMV transactions, we only need the transactionId and paypalInvoiceId
 * values of this object, so you can make one up with that data.
 * @param destination the destination for the receipt (e.g. an email address or phone number)
 * @param completionHandler called when the receipt is sent or an error occurs
 */
- (void)beginSendReceipt: (PPHPaymentResponse*) payment to: (PPHReceiptDestination*) destination completionHandler: (PPHInvoiceBasicCompletionHandler) completionHandler;

@end

#define kPPHPaymentErrorDomain      @"PPH.Payment"
#define kPPHCaptureFailedErrorCode  0xdeadbeef
#define kPPHVoidFailedErrorCode     0xd00dbeef
#define kPPHRefundFailedErrorCode   0xdaadbeef

