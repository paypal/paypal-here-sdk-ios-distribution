//
//  PPHTransactionManager.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 8/13/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "PPHCardNotPresentData.h"
#import "PPHCardReaderManager.h"
#import "PPHInvoice.h"
#import "PPHLocalErrors.h"
#import "PPHLocationCheckin.h"
#import "PPHPaymentConstants.h"
#import "PPHTransactionControllerDelegate.h"
#import "PPHTransactionManagerDelegate.h"
#import "PPHTransactionRecord.h"
#import "PPHTransactionResponse.h"




typedef void (^PPHTransactionCompletionHandler) (PPHTransactionResponse *response);
typedef void (^PPHReceiptCompletionHandler) (PPHTransactionRecord *record);


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPHTransactionManager : NSObject

/*! The invoice used for this transaction. */
@property (nonatomic, strong) PPHInvoice *currentInvoice;
/*!
 * Card swipe data we'll use if the PaymentType is CardReader.
 */
@property (nonatomic, strong) PPHCardSwipeData* encryptedCardData;
/*!
 * Card swipe data we'll use if the PaymentType is ManualEntry
 */
@property (nonatomic, strong) PPHCardNotPresentData* manualEntryOrScannedCardData;
@property (nonatomic, strong) PPHLocationCheckin* checkedInClient;  // The checked in client to charge against.

/*!
 * Discover if we're busy processing a payment we the back end.
 * @return a boolean value.  Returns true if we're currently processing a finalizePayment
 */
@property (nonatomic, readonly) BOOL isProcessingPayment;

/*!
 * Discover if we're currently handling a transaction.  While handling a transaction
 * we can accept an invoice.  If configured to work with the hardware scanners (the 
 * default) we will also be scanning for card swipes.
 * @return a boolean value.  Returns true if we're currently handling a transaction.
 */
@property (nonatomic, readonly) BOOL hasActiveTransaction;

/*!
 * Configure the TransactionManager to ignore OR work with any payment readers that might
 * be attached.
 *
 * The default behavior is for the TransactionManager to work with attached payment readers.  If
 * that is the desired behavior there is no need to call this method.
 *
 * It is not legal to call this method during a transaction.  Complete your transaction first, then
 * change this setting.   Calling setIgnoreHardwareReaders during a transaction will have no effect.
 *
 * Pass YES to ignore readers, NO to include them
 */
@property (nonatomic, assign) BOOL ignoreHardwareReaders;

/*!
 * Determines if the current transaction will request a signature or not for a given amount.
 *
 * @param amountOrNil The amount to test against, or nil if you would like to use the current invoice total.
 * @param paymentMethod The payment method. If it is ePPHPaymentMethodUnknown the method of the current payment is used.
 */
- (BOOL)transactionRequiresSignatureForAmount:(PPHAmount *)amountOrNil paymentMethod:(PPHPaymentMethod)paymentMethod;

/*!
 * Determines if we can bypass signature if it is not essential to the payment environment.
 *
 * If YES then we always request a signature when it would normally be optional (swipe, contactless MSD)
 *
 * If NO we will respect the directions from the EMV chip or from the payment limits account configuration when determining when to request a signature
 *
 * Default value is NO
 *
 */
@property (nonatomic, assign) BOOL requireSignatureWhenApplicable;

/*!
 * If set to YES when attempting to activate the reader instead we will first display a prompt for
 * a user to enter an amount on the reader that will be added to the invoice as a gratuity. After
 * the gratuity amount is collected the reader will then be activated.
 *
 * Defaults to NO
 */
@property (nonatomic, assign) BOOL shouldPromptForOnReaderTips;

/*!
 * If set to YES when on reader tipping is enabled the reader will prompt for and collect a
 * gratuity amount as percentage rather than amount. Once entered the percentage will be multiplied
 * with the current invoice's subtotal and applied as a gratuity amount.
 *
 * Defaults to NO
 */
@property (nonatomic, assign) BOOL usePercentageOnReaderTips;

/*!
 * The amount of time in seconds we will wait before explicitly putting the reader to sleep when not
 * in a transaction.
 *
 * The default value is read from a configuration file that PayPal believes represents the best time
 * to conserve battery without sacrificing to much user experience. If your use case or opinion
 * requires otherwise you may change it here.
 *
 * A value less than zero will cause the reader to never explicitly sleep.
 * A value of NSTimeIntervalSince1970 will cause the SDK to use the PayPal configured value.
 *
 * At the time of writing this comment the configured value is 60 seconds.
 */
@property (nonatomic, assign) NSTimeInterval readerSleepDelay;

/*! beginPayment puts us in a state to take a payment.  
 * You can now set the shoppingCart, signature, and extras 
 */

/*! 
 * Used to begin all types of payment (check-in, card present, manual entry, cash, etc) 
 * This call causes the hardware enabled version of the SDK to start scanning for card swipes.
 * the currentInvoice is initialized with an empty inventory for you to add items to.
 */
- (void)beginPayment;

/*!
 * Begin a fixed amount payment.  Similar to beginPayment except this time the 
 * TransactionManager's invoice object becomes primed with an invoice containing
 * the fixed amount item.
 *
 * @param amount the amount to charge the customer.
 * @param itemName the name for this item.  Will be stored in the invoice.
 */
- (void)beginPaymentWithAmount:(PPHAmount*) amount andName:(NSString *)itemName;

/*!
 * Begin a payment use a given invoice.
 *
 * @param invoice the invoice which is tracking the current purchase.
 */
- (void)beginPaymentWithInvoice:(PPHInvoice*) invoice;

/*!
 * Clears the current state of the transaction, including current invoice, card data, etc, thus 
 * returning back to an Idle state.
 *
 * Returns an error if unable to clear the states. This could happen if we are in the middle of processing 
 * a transaction. Else, returns nil.
 */
- (PPHError *)cancelPayment;


/*!
 * Authorize a payment.  Used with either Checkin (ePPHPaymentMethodPaypal) or a card 
 * payment (ePPHPaymentMethodSwipe, ePPHPaymentMethodKey).   Allows you to authorize an amount.
 *
 * Once authorized you can be confident that PayPal will allow capture on up to 115% of the amount
 * authorized (allows for later adding of tips or later adding of some line items just prior to
 * capturing the payment.
 *
 * However, if the merchant's account is so enabled, this capture limit can be upto 500%   See 
 * PPHPaymentLimits.captureTolerance for more information
 *
 * After authorization is successful you can then, at a later time or immediately afterwards, call 
 * capturePaymentForAuthorization to actually capture your money or you can call voidAuthorization
 * to discard the payment.
 *
 * @param paymentMethod What type of authorization we are doing.  Can be ePPHPaymentMethodPaypal (checkin)
 *                      or ePPHPaymentMethodSwipe or ePPHPaymentMethodKey
 *
 * @param completionHandler Will return a PPHTransactionResponse.  If there's an error then the PPHTransactionRecord's
 * error object will be non nil.  Otherwise it will contain a PPHTransactionRecord which you can 
 * later pass into voidAuthoriztion or capturePaymentForAuthorization
 */
- (void)authorizePaymentWithPaymentType:(PPHPaymentMethod)paymentMethod
                   withCompletionHandler:(PPHTransactionCompletionHandler)completionHandler;

/*!
 * Allows you to void a previously authorized payment.  
 * @param authorizedTransactionRecord
 * @param completionHandler will return a PPHTransactionResponse.  If there's an error then the PPHTransactionRecord's
 * error object will be non nil.  Otherwise it will contain a PPHTransactionRecord for this void action.
 */
- (void)voidAuthorization:(PPHTransactionRecord *)authorizedTransactionRecord
     withCompletionHandler:(PPHTransactionCompletionHandler)completionHandler;

/*!
 * Captures a prevoisly authorized payment.  
 *
 * In most cases you can capture at 115% of what was previously authorized.  
 *
 * However, if the merchant's account is so enabled, this capture limit can be upto 500%   See
 * PPHPaymentLimits.captureTolerance for more information
 *
 * To capture more or less than was authorized you can add a gratutity or add/remove line items 
 * from the invoice contained in the PPHTransactionRecord you pass in.  If you don't wish to add
 * a gratutity or change line items just supply the transactionRecord you received when you 
 * authorized the transaction.
 *
 * @param authorizedTransactionRecord  This is the PPHTransactionRecord you received in the
 * authorizePayment call.  This tells the SDK what auth you'd like to capture.  
 *
 * @param completionHandler : Will return a PPHTransactionResponse.  If there's an error 
 * then the PPHTransactionRecord's error object will be non nil.
 */
- (void)capturePaymentForAuthorization:(PPHTransactionRecord *)authorizedTransactionRecord
                  withCompletionHandler:(PPHTransactionCompletionHandler)completionHandler;

/*!
 * Process a payment given a payment type of card, cash, cheque, checked-In-Client, etc.
 *
 * Processing a payment for swipe or key-in or checkin-in payments will
 * actually capture that payment.  For Cash or Check, this call will simply
 * record the invoice into the paypal system for record-keeping purposes.
 *
 * @param paymentType the type of payment to collect.  You'll get an error back if you 
 *                    specify ePPHPaymentTypesCheckedInPayment and haven't set the
 *                    checkedInClient property.  Likewise with the cardData member and 
 *                    specifying ePPHPaymentMethodSwipe.
 *
 * @param controller  Can be nil.  If provided, the transaction manager will call the callbacks
 *                    defined in the PPHTransactionControllerDelegate.
 * @param completionHandler called when the action has completed
 */
- (void)processPaymentWithPaymentType:(PPHPaymentMethod) paymentType
              withTransactionController:(id<PPHTransactionControllerDelegate>)controller
                      completionHandler:(PPHTransactionCompletionHandler) completionHandler;





/*!
 * Used to capture the signature of the customer if it already hasn't been captured in the processPayment call
 * and complete the transaction.
 *
 * Can be used to provide a signature in both the sale (processPayment) and auto/capture flows. 
 * After processPayment returns you can then provide a signature using the PPHTransactionRecord returned by processPayment.
 * After an authorization you can provide the signature either before or after a capture.
 *
 * @param signature : A UIImage contining the signature of the customer.
 * @param previousTransaction : The transaction record object that is returned back from the processPayment call.
 * @param completionHandler : A response handler that would be invoked by the SDK in case of a success or a failure.
 */
- (void)provideSignature:(UIImage *)signature forTransaction:(PPHTransactionRecord *)previousTransaction completionHandler: (void (^)(PPHError *))completionHandler;


/*!
 * Issue a refund against a previously successful PayPal transaction.
 * @param previousTransaction   The transaction identifier for the original payment transaction.
 *                              If you want to send a receipt and you don't have a PPHTransactionRecord you can construct one.  Just make
 *                              sure it at least has the transactionId set.  Other params being set is ok, they will not be accessed
 *                              by beginRefund.
 *
 * @param amountOrNil           Only pass an amount in the case of a partial refund. Otherwise, the backend will ensure it's a full refund.
 * @param completionHandler     Called when the action has completed
 */
- (void)beginRefund:(PPHTransactionRecord*) previousTransaction forAmount: (PPHAmount*) amountOrNil completionHandler: (PPHTransactionCompletionHandler) completionHandler;

/*!
 * Used to send the receipt of a transaction to a customer based on the email address or the phone number provided.
 *
 * @param previousTransaction : The transaction record object that is returned back from the processPayment call. This will
 *               contain the invoice id and transaction id etc needed to send the receipt.
 *
 *               If you want to send a receipt and you don't have a PPHTransactionRecord you can construct one.  Just make 
 *               sure it has BOTH the transactionId and payPalInvoiceId properties set.
 * @param destination : A PPHReceiptDestination object which describes either the email address or phone number to
 *                      which we should send the receipt.
 * @param completionHandler : A response handler that would be invoked by the SDK in case of a success or a failure.
 */
- (void)sendReceipt:(PPHTransactionRecord*) previousTransaction toRecipient:(PPHReceiptDestination*)destination completionHandler: (PPHInvoiceBasicCompletionHandler) completionHandler;


/**
 * This api is used to activate the EMV reader to start listening/processing for payments.
 * @param error : If an error occurs, upon return contains a PPHError object that describes the problem.
                  Pass in NULL if you do not want error reporting.
 */
- (BOOL)activateReaderForPayments:(PPHError**)error;


/**
 * This api is used to stop the EMV reader from looking for payments.
 */
- (void)deActivateReaderForPayments;


@end

/*
 * Transaction Manager flows that present custom UI to facilitate EMV transactions.
 * It is impossible to take an EMV transaction without entering through these endpoints.
 */
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPHTransactionManager (EMV)

- (void)beginPaymentUsingUIWithInvoice:(PPHInvoice*)invoice transactionController:(id<PPHTransactionControllerDelegate>)controller;
- (void)processPaymentUsingUIWithPaymentType:(PPHPaymentMethod)paymentType completionHandler:(PPHTransactionCompletionHandler) completionHandler;

- (void)beginRefundUsingUIWithInvoice:(PPHInvoice*)invoice transactionController:(id<PPHTransactionControllerDelegate>)controller;
- (void)processRefundUsingUIWithAmount:(PPHAmount*)amount completionHandler:(PPHTransactionCompletionHandler)completionHandler;

//If Destination is nil, we offer a choice of receipts. If not, we use Phone or Email UI depending on what's there. We then autofill destination.
- (void)sendReceiptUsingUIWithTransactionRecord:(PPHTransactionRecord *)record amount:(PPHAmount *)transactionAmount transactionController:(id<PPHTransactionControllerDelegate>)transactionController destination:(PPHReceiptDestination *)destination completionHandler:(PPHReceiptCompletionHandler)completionHandler;

@end
