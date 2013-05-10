//
//  PPHPaymentProcessor.h
//  PayPalHereSDK
//
//  Created by Max Metral on 10/30/12.
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHInvoiceProtocol.h"
#import "PPHCardNotPresentData.h"

/*!
 * All network requests around payment will use this id (which can be passed to the network delegate to cancel them)
 */
#define kPPHPaymentNetworkRequestId @"PPHPayment"

@class PPHChipAndPinAuthEvent;
@class PPHChipAndPinEventWithEmv;
@class PPHLocationTab;
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
 * Non-nil if the transaction has succeeded and has a reference number
 */
@property (nonatomic,strong) NSString* transactionId;
/*!
 * The invoiceId of the invoice this payment was made against.
 */
@property (nonatomic,strong) NSString* paypalInvoiceId;
/*!
 * The correlation ID of the transaction attempt.
 */
@property (nonatomic,strong) NSString* correlationId;
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
-(void)beginRefund: (NSString*) transactionId forAmount: (PPHAmount*) amountOrNil completionHandler: (void(^)(PPHPaymentResponse*)) completionHandler;

#pragma mark - Local/Tab payment
/*!
 * Capture funds against an open tab from PPHLocalManager and PPHLocationWatcher
 * @param tab information about the tab (only id is needed)
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)beginTabPayment: (PPHLocationTab*) tab forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^)(PPHPaymentResponse*)) completionHandler;

#pragma mark - Card related payment options

/*!
 * Authorize a chip and pin card after pin has been validated
 * @param auth from PPHCardReaderManager auth event.
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)beginChipAndPinAuthorization:(PPHChipAndPinAuthEvent*) auth forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^)(PPHChipAndPinAuthResponse *response)) completionHandler;

/*!
 * Collect funds against a card that has been passed through a reader and for which magstripe data is available.
 * @param card from PPCardReaderManager swipe event
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 * @param signature Currently, the signature must be captured before the transaction attempt. We will be fixing this bug over the coming months.
 */
-(void)beginCardPresentChargeAttempt: (PPHCardSwipeData*) card forInvoice: (id<PPHInvoiceProtocol>) invoice withSignature: (UIImage*) signature completionHandler: (void (^)(PPHCardChargeResponse *response)) completionHandler;

/*!
 * Collect funds against a card that has been manually entered.
 * @param card Filled out manually or via a Card Scan
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)beginCardNotPresentChargeAttempt: (PPHCardNotPresentData*) card forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^) (PPHCardChargeResponse *response)) completionHandler;

/*!
 * Provide a signature record for a previously successful charge. TODO - currently we expect this to be gathered before the card present attempt, which is unpleasant.
 * @param signature the buyer-generated signature
 * @param response the result of beginCardPresentChargeAttempt
 * @param completionHandler called when the action has completed
 */
-(void)provideSignature: (UIImage*) signature forTransaction: (PPHCardChargeResponse*) response completionHandler: (void (^)(PPHError *error)) completionHandler;

/*!
 * Capture funds against a chip&pin or chip card
 * @param approvalFromTerminalOrNil for chip&pin card, this is passed to you by PPHCardReaderManager event
 * @param auth for chip&pin card, this is passed to you by PPHCardReaderManager event
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 */
-(void)finalizeChipAndPin: (PPHChipAndPinEventWithEmv*) approvalFromTerminalOrNil withAuth: (PPHChipAndPinAuthResponse*) auth forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^) (PPHCardChargeResponse* response)) completionHandler;

/*!
 * Capture funds against a chip&pin&signature or chip&signature card
 * @param approvalFromTerminalOrNil for chip&pin card, this is passed to you by PPHCardReaderManager event
 * @param auth for chip&pin card, this is passed to you by PPHCardReaderManager event
 * @param invoice the invoice on which to collect funds (total, currency, invoiceId are the main elements). You must save this invoice before
 * attempting to collect payment.
 * @param completionHandler called when the action has completed
 * @param signature the buyer-generated signature
 */
-(void)finalizeChipAndPin: (PPHChipAndPinEventWithEmv*) approvalFromTerminalOrNil withSignature: (UIImage*) signature andAuth: (PPHChipAndPinAuthResponse*) auth forInvoice: (id<PPHInvoiceProtocol>) invoice completionHandler: (void (^) (PPHCardChargeResponse* response)) completionHandler;

/*!
 * Check if the given swipe data is for the same card that the invoice was paid with
 * @param card the card data to be checked
 * @param invoice the invoice against which to check the card
 * @param completionHandler called when the action has completed
 */
-(void)checkRefundEligibilityForCardPresent:(PPHCardSwipeData*)card andInvoice:(id<PPHInvoiceProtocol>)invoice completionHandler:(void(^)(PPHRefundEligibilityResponse*))completionHandler;


/*!
 * Check if the given chip+pin card data is for the same card that the invoice was paid with
 * @param auth the chip+pin card data to be checked
 * @param invoice the invoice against which to check the card
 * @param completionHandler called when the action has completed
 */
-(void)checkRefundEligibilityForChipAndPin:(PPHChipAndPinAuthEvent*)auth andInvoice:(id<PPHInvoiceProtocol>)invoice completionHandler:(void(^)(PPHRefundEligibilityResponse*))completionHandler;

/*!
 * Check if the given event contains the same EMV data as the card that the invoice was paid with
 * @param event the terminal decline event that contains EMV data
 * @param invoice the invoice against which to check the card
 * @param completionHandler called when the action has completed
 */
-(void)checkRefundEligibilityForDeclinedCardWithEvent:(PPHChipAndPinEventWithEmv*)event andInvoice:(id<PPHInvoiceProtocol>)invoice completionHandler:(void(^)(PPHRefundEligibilityResponse*))completionHandler;

@end
