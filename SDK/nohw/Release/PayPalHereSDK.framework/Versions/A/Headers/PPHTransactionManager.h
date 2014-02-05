//
//  PPHTransactionManager.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 8/13/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHTransactionManagerDelegate.h"
#import "PPHTransactionControllerDelegate.h"
#import "PPHCardNotPresentData.h"
#import "PPHInvoice.h"

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

@class PPHCardSwipeData;
@class PPHShoppingCart;
@class PPHAmount;
@class PPHPaymentResponse;
@class PPHCardChargeResponse;
@class PPHError;
@class PPHTransactionRecord;
@class PPHLocationCheckin;
@class PPHTransactionControllerWatcher;
@class PPHReceiptDestination;

// The set of local payment errors that might be generated.
// TODO: check the -2000 number space to ensure we're not colliding with something else.
#define kPPHLocalErrorBadConfigurationNoCheckedInClient -2000
#define kPPHLocalErrorBadConfigurationNoCardData -2001
#define kPPHLocalErrorBadConfigurationNoManualCardData -2002
#define kPPHLocalErrorBadConfigurationNoMerchant -2003
#define kPPHLocalErrorBadConfigurationNoRecord -2004
#define kPPHLocalErrorBadConfigurationInvalidState -2005


// Some NSString constants used by the PPHTransactionWatcher:
#define kPPHTransactionManagerStateChange	@"PPH.TransactionManager.StateChange"
#define kPPHTransactionManagerEventKey		@"PPH.TransactionManager.EventKey"


@interface PPHTransactionResponse : NSObject
/*!
 * Non-nil if an error has occurred in processing the payment.
 */
@property (nonatomic,strong) PPHError* error;
@property (nonatomic,strong) PPHTransactionRecord* record;  //correlation id, transaction id, etc.

/*!
 *  If YES then the app should supply a signature image using the finalizePaymentForTransaction call
 */
@property (nonatomic,assign) BOOL isSignatureRequiredToFinalize;

@end

/*!
 * A stateful transaciton (payment & refunds) processor. 
 * Here are some usage examples:
 *
 * Usage for a fixed amount payment with a card reader:
 *
 *  // Let's charge this user $5.  First, call beginPaymentWithAmount.  This will cause
 *  // us to start scanning for swipes from any attached reader.
 *
 *  -(void) onPurchaseButtonClicked() {
 *     PPHAmount *fiveDollarAmount = [PPHAmount [PPHAmount amountWithString:@"5.00" inCurrency:@"USD"];
 *     [[PayPalHereSDK sharedTransactionmanager] beginPaymentWithAmount:fiveDollarAmount withName:@"FixedAmount"];
 *  }
 *
 *  // Once the card is swiped your ___ method will be called.   
 *  // Now we can ask the TransactionManager to take payment using the card data:
 *   
 *  -(void)didCompleteCardSwipe:(PPHCardSwipeData*)card {
 *     self.waitingForCardSwipe = NO;
 *     [[PayPalHereSDK sharedTransactionmanager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe
 *                                                     withTransactionController:nil
 *                                                             completionHandler:^(PPHTransactionResponse *record) {
 *                 NSLog(@"Transaction Finished! Success: %@", record.error ? @"NO" : @"YES");
 *                 //Now that the transaciton is complete the PPHTransactionManager will stop scanning for card swipes.
 *     }];
 *
 *
 *
 *
 * Usage for a fixed amount payment with a manually entered card:
 *
 *  // Let's charge this user $5.  First, call beginPaymentWithAmount.  Then we can immediatly set
 *  // the manually entered card data and authorize (take) the payment.
 *
 *  -(void) onPurchaseButtonClicked() {
 *     PPHAmount *fiveDollarAmount = [PPHAmount [PPHAmount amountWithString:@"5.00" inCurrency:@"USD"];
 *     NSDateComponents *comps = [[NSDateComponents alloc] init];
 *     [comps setMonth:9];
 *     [comps setYear:2019];
 *
 *     PPHCardNotPresentData *manualCardData = [[PPHCardNotPresentData alloc] init];
 *     manualCardData.cardNumber = @"4111111111111111";
 *     manualCardData.cvv2 = @"408";
 *     manualCardData.expirationDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
 *
 *     [[PayPalHereSDK sharedTransactionmanager] beginPaymentWithAmount:fiveDollarAmount withName:@"FixedAmount"];
 *     [PayPalHereSDK sharedTransactionmanager].manualEntryOrScannedCardData = manualCardData;
 *     [tm processPaymentWithPaymentType:ePPHPaymentMethodKey
 *               withTransactionController:nil
 *                       completionHandler:^(PPHTransactionResponse *record) {
 *                                  NSLog("Payment Completed");
 *      }];
 *  }
 *
 *
 */

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
 * Configure the TransactionManager to start and stop listening for card swipes while performing a
 * transaction. By default, the TransactionManager performs this action but, if the application would
 * like to take control of this, set the boolean param to false. This would expect the application to
 * make use of CardReaderManager's WaitForAuthorization and CancelWaitForAuthorization
 * APIs to start and stop listening for card swipes.
 *
 * Set to NO if the application would like to make use of the CardReaderManager's API to start and
 * stop listening for card swipes.
 *
 * Set to YES if the apps wants the SDK (TransactionManager) to automatically start and stop listening
 * for card swipes. This is the default behavior.
 */
@property (nonatomic, assign) BOOL cardReaderMonitorEnabled;

/**
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

/*! beginPayment puts us in a state to take a payment.  
 * You can now set the shoppingCart, signature, and extras 
 */

/*! 
 * Used to begin all types of payment (check-in, card present, manual entry, cash, etc) 
 * This call causes the hardware enabled version of the SDK to start scanning for card swipes.
 * the currentInvoice is initialized with an empty inventory for you to add items to.
 */
-(void)beginPayment;

/*!
 * Begin a fixed amount payment.  Similar to beginPayment except this time the 
 * TransactionManager's invoice object becomes primed with an invoice containing
 * the fixed amount item.
 *
 * @param amount the amount to charge the customer.
 * @param itemName the name for this item.  Will be stored in the invoice.
 */
- (void) beginPaymentWithAmount:(PPHAmount*) amount andName:(NSString *)itemName;

/*! 
 * give up on the current payment if possible (if not already capturing payment).   Clears state members. 
 */
-(PPHError *) cancelPayment;

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
-(void) processPaymentWithPaymentType:(PPHPaymentMethod) paymentType
              withTransactionController:(id<PPHTransactionControllerDelegate>)controller
                      completionHandler:(void (^)(PPHTransactionResponse *record)) completionHandler;

/*!
 * Used to capture the signature of the customer if it already hasn't been captured in the processPayment call
 * and complete the transaction.
 * In case of EMV related payments, this API should be used after the processPayment call has been
 * approved by the terminal. If the terminal declines, the transaction would be voided.
 *
 * @param previousTransaction : The transaction record object that is returned back from the processPayment call.
 * @param signature : A bitmap signature of the customer.
 * @param completionHandler : A response handler that would be invoked by the SDK in case of a success or a failure.
 */
-(void)finalizePaymentForTransaction:(PPHTransactionRecord *)previousTransaction withSignature:(UIImage *)signature completionHandler: (void (^)(PPHError *))completionHandler;

/*!
 * Issue a refund against a previously successful PayPal transaction.
 * @param previousTransaction The transaction identifier for the original payment transaction
 * @param amountOrNil Only pass an amount in the case of a partial refund. Otherwise, the backend will ensure it's a full refund.
 * @param completionHandler called when the action has completed
 */
-(void)beginRefund:(PPHTransactionRecord*) previousTransaction forAmount: (PPHAmount*) amountOrNil completionHandler: (void(^)(PPHPaymentResponse*)) completionHandler;

/**
 * Used to send the receipt of a transaction to a customer based on the email address or the phone number provided.
 *
 * @param previousTransaction : The transaction record object that is returned back from the processPayment call. This will
 *               contain all the necessary information required such as the invoice id,
 *               transaction id etc needed to send the receipt.
 *               Use this API when the transaction record is available. For example,
 *               when the transaction is successful.
 * @param destination : A PPHReceiptDestination object which describes either the email address or phone number to 
 *                      which we should send the receipt.
 * @param completionHandler : A response handler that would be invoked by the SDK in case of a success or a failure.
 */
-(void)sendReceipt:(PPHTransactionRecord*) previousTransaction toRecipient:(PPHReceiptDestination*)destination completionHandler: (PPHInvoiceBasicCompletionHandler) completionHandler;

@end
