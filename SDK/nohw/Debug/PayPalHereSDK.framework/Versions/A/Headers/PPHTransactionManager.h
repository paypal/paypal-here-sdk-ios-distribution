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
#import "PPHCardReaderManager.h"
#import "PPHLocalErrors.h"

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

// Mapping the different API's in Transaction Manager to key's
// used in saving of invoice, and can be extended for other future use cases
#define kPPHTransactionManagerAPIAuthorizePayment -3000
#define kPPHTransactionManagerAPICapturePayment -3001
#define kPPHTransactionManagerAPIProcessPayment -3002


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
 * This flag indicates whether the customer asked for a print receipt at the end of the SDK flow.
 * The SDK itself does not support any printers or printer integration; instead it is up to the
 * integrating application to provide print receipts based on feedback available in the transaction
 * response and this flag
 */
@property (nonatomic,assign) BOOL didRequestPrintReceipt;

/*!
 *  If YES then the app should supply a signature image using the finalizePaymentForTransaction call
 */
@property (nonatomic,assign) BOOL isSignatureRequiredToFinalize;

@end

/** A stateful transaction (payment & refunds) processor.
    Here are some usage examples:
 
    Already have a PPHInvoice filled out and want to take payment with a card reader?
  
    First, call beginPayment.  This will cause
    us to start scanning for swipes from any attached reader.
 
    -(void) onPurchaseButtonClicked {
        [[PayPalHereSDK sharedTransactionmanager] beginPayment];
    }

    If your class has implemented the PPHTransactionManagerDelegate protocol and
    created a PPHTransactionWatcher then your onPaymentEvent method will be called when
    the user swipes their card.
    Now we can ask the TransactionManager to take payment using the card data:
 
    -(void)onPaymentEvent:(PPHTransactionManagerEvent *) event {
        if (event.eventType == ePPHTransactionType_CardDataReceived) {
 
          [[PayPalHereSDK sharedTransactionmanager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe
                                                      withTransactionController:nil
                                                              completionHandler:^(PPHTransactionResponse *record) {
                  NSLog(@"Transaction Finished! Success: %@", record.error ? @"NO" : @"YES");
                  //Now that the transaction is complete the PPHTransactionManager will stop scanning for card swipes.
          }];
    }

    Usage for a fixed amount payment with a card reader:
 
    Let's charge this user $5.  First, call beginPaymentWithAmount.  This will cause
    us to start scanning for swipes from any attached reader.
 
    -(void) onPurchaseButtonClicked {
        PPHAmount *fiveDollarAmount = [PPHAmount [PPHAmount amountWithString:@"5.00"];
        [[PayPalHereSDK sharedTransactionmanager] beginPaymentWithAmount:fiveDollarAmount withName:@"FixedAmount"];
    }
 
    If your class has implemented the PPHTransactionManagerDelegate protocol and
    created a PPHTransactionWatcher then your onPaymentEvent method will be called when
    the user swipes their card.
    Now we can ask the TransactionManager to take payment using the card data:
    
    -(void)onPaymentEvent:(PPHTransactionManagerEvent *) event {
 
        if (event.eventType == ePPHTransactionType_CardDataReceived) {
 
          [[PayPalHereSDK sharedTransactionmanager] processPaymentWithPaymentType:ePPHPaymentMethodSwipe
                                                      withTransactionController:nil
                                                              completionHandler:^(PPHTransactionResponse *record) {
                  NSLog(@"Transaction Finished! Success: %@", record.error ? @"NO" : @"YES");
                  //Now that the transaction is complete the PPHTransactionManager will stop scanning for card swipes.
          }];
    }
 
 
    Usage for a fixed amount payment with a manually entered card:
 
    Let's charge this user $5.  First, call beginPaymentWithAmount.  Then we can immediatly set
    the manually entered card data and authorize (take) the payment.
    Note that the SDK will start scanning for card swipes after the call to beginPaymentWithAmount
    even if you eventually intend to take a manual payment.   Once your call to processPaymentWithPaymentType
    is made we'll then stop scanning for swipes.
 
    -(void) onPurchaseButtonClicked {
        PPHAmount *fiveDollarAmount = [PPHAmount [PPHAmount amountWithString:@"5.00"];
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setMonth:9];
        [comps setYear:2019];
 
        PPHCardNotPresentData *manualCardData = [[PPHCardNotPresentData alloc] init];
        manualCardData.cardNumber = @"4111111111111111";
        manualCardData.cvv2 = @"408";
        manualCardData.expirationDate = [[NSCalendar currentCalendar] dateFromComponents:comps];
 
        [[PayPalHereSDK sharedTransactionmanager] beginPaymentWithAmount:fiveDollarAmount withName:@"FixedAmount"];  // We start scanning for swipes
        [PayPalHereSDK sharedTransactionmanager].manualEntryOrScannedCardData = manualCardData;
        [tm processPaymentWithPaymentType:ePPHPaymentMethodKey
                withTransactionController:nil
                        completionHandler:^(PPHTransactionResponse *record) {
                                   NSLog("Payment Completed"); // We now stop scanning for swipes.
        }];
    }
 
    AUTH & CAPTURE
 
    The SDK allows you to authorize an amount on a credit card.  Then, later, you can make a follow
    up call to capture that amount.  If the customer added a tip you can also capture with the additional
    tip.  You can also void the authorization.  You can also capture with not just the addition of a
    tip, but also with the addition of invoice items.
 
    Here is an example of an authorization on a credit card:
 
    -(void) onPurchaseButtonClicked {
        PPHAmount *twentyDollarAmount = [PPHAmount [PPHAmount amountWithString:@"20.00"];
        [[PayPalHereSDK sharedTransactionmanager] beginPaymentWithAmount:twentyDollarAmount withName:@"FixedAmount"];
    }
 
    -(void)onPaymentEvent:(PPHTransactionManagerEvent *) event {
 
        if (event.eventType == ePPHTransactionType_CardDataReceived) {
 
            Let's authorize the $20 payment for the card that was swiped.
            This causes the SDK to stop monitoring for swipes.
 
           [[PayPalHereSDK sharedTransactionManager] authorizePaymentWithPaymentType:ePPHPaymentMethodSwipe
                                                       withCompletionHandler:^(PPHTransactionResponse *response) {
                                                               // Authorization complete!  (well, check response.error first!)
                                                               // Save the PPHTransactionResponse for later use during the capture.
                                                               self.myAuthorizedPaymentTransactionResponse = response;
 
           }];
        }
    }
 
 
 
    Here is an example of capturing payment on a previously completed authorization
 
    - (void) capturePaymentButtonPressed {
        [[PayPalHereSDK sharedTransactionManager] capturePaymentForAuthorization:_myAuthorizedPaymentTransactionResponse.record
                                                         withCompletionHandler:^(PPHTransactionResponse *response) {
                                                               if(!response.error) {
                                                                   NSLog(@"Payment captured!");
        }
    }
 
  
    Here's an example of capturing payment with a tip.
 
    - (void) capturePaymentButtonPressed {
 
        NSDecimalNumber *gratuityToAdd = self.gratuityEnteredByCustomer; // Let's use the gratuity your customer entered via your UI
 
        _myAuthorizedPaymentTransactionResponse.record.invoice.gratuity = gratuityToAdd;
 
        [[PayPalHereSDK sharedTransactionManager] capturePaymentForAuthorization:_myAuthorizedPaymentTransactionResponse.record
                                                         withCompletionHandler:^(PPHTransactionResponse *response) {
                                                               if(!response.error) {
                                                                   NSLog(@"Payment captured with Tip!");
        }
    }
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

/**
 * Configure the Transaction Manager to ignore OR obey PayPal's backend-based signature required above "x" amount configuration,
 * (also referred to as the default signature setting) which could also be obtained via the "TransactionResponse.isSignatureRequiredToFinalize" property.
 *
 * When the application invokes the "setActiveMerchant" API, the SDK would go ahead and fetch various configuration and properties 
 * for this merchant.
 *
 * One of the properties provided to the SDK would include the minimum amount above which a signature is required.
 *
 * This enables the transaction manager to move to a " Waiting For Signature " state and expects the application
 * to invoke the "provideSignature" API after the completion of the 'ProcessPayment" API (when an amount > minimum required for signature).
 *
 * If the app chooses to override this behavior and not collect a signature for ANY amount, they must set this property as YES. This would enable
 * the transaction manager to ignore the backend-based (a.k.a isSignatureRequiredToFinalize) setting and move to an idle state once the payment is
 * complete.
 *
 * If set to NO, in conjunction with the backend-based setting (a.k.a isSignatureRequiredToFinalize), the SDK would expect the application to invoke the
 * "provideSignature" API after the completion of the "processPayment" API.
 *
 * Default value set to NO.
 *
 * NOTE : This property would ONLY be applicable for Swipe based transactions and will not be considered while performing any EMV related transactions.
 *
 */
@property (nonatomic, assign) BOOL shouldAppOverrideDefaultSignatureSetting;

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
 * Clears the current state of the transaction, including current invoice, card data, etc, thus 
 * returning back to an Idle state.
 *
 * Returns an error if unable to clear the states. This could happen if we are in the middle of processing 
 * a transaction. Else, returns nil.
 */
-(PPHError *) cancelPayment;


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
- (void) authorizePaymentWithPaymentType:(PPHPaymentMethod)paymentMethod
                   withCompletionHandler:(void (^)(PPHTransactionResponse *))completionHandler;

/*!
 * Allows you to void a previously authorized payment.  
 * @param authorizedTransactionRecord
 * @param completionHandler will return a PPHTransactionResponse.  If there's an error then the PPHTransactionRecord's
 * error object will be non nil.  Otherwise it will contain a PPHTransactionRecord for this void action.
 */
- (void) voidAuthorization:(PPHTransactionRecord *)authorizedTransactionRecord
     withCompletionHandler:(void (^)(PPHTransactionResponse *))completionHandler;

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
- (void) capturePaymentForAuthorization:(PPHTransactionRecord *)authorizedTransactionRecord
                  withCompletionHandler:(void (^)(PPHTransactionResponse *))completionHandler;

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
 * Process a payment given a payment type of card, cash, cheque, checked-In-Client, etc.
 * This version will cause the SDK to show UI during the payment flow.
 *
 * Currently only supported for when taking an EMV payment (ePPHPaymentMethodChipCard).
 *
 * Processing a payment for swipe or key-in or checkin-in payments will
 * actually capture that payment.  For Cash or Check, this call will simply
 * record the invoice into the paypal system for record-keeping purposes.
 *
 * @param paymentType : The type of payment to collect.  You'll get an error back if you
 *                    specify ePPHPaymentTypesCheckedInPayment and haven't set the
 *                    checkedInClient property.  Likewise with the cardData member and
 *                    specifying ePPHPaymentMethodSwipe.
 *
 * @param vc : The current or active view controller.
 *
 * @param controller :  Can be nil.  If provided, the transaction manager will call the callbacks
 *                    defined in the PPHTransactionControllerDelegate.
 * @param completionHandler : called when the action has completed
 */
-(void) processPaymentUsingSDKUI_WithPaymentType:(PPHPaymentMethod) paymentType
                       withTransactionController:(id<PPHTransactionControllerDelegate>)controller withViewController: (UIViewController *)vc
                               completionHandler:(void (^)(PPHTransactionResponse *record)) completionHandler;

/*!
  * Refund a payment given a type of card, cash, cheque, checked-In-Client, etc.
  * This version will cause the SDK to show UI during the refund flow.
  *
  * Currently only supported for when taking an EMV refund (ePPHPaymentMethodChipCard).
  *
  * @param paymentType the type on which the refund would be performed.  You'll get an error back if you
  *                    specify ePPHPaymentTypesCheckedInPayment and haven't set the
  *                    checkedInClient property.  Likewise with the cardData member and
  *                    specifying ePPHPaymentMethodSwipe.
  *
  * @param vc : The current or active view controller.
  *
  * @param completionHandler called when the action has completed
  */
-(void) beginRefundUsingSDKUI_WithPaymentType:(PPHPaymentMethod) paymentType withViewController: (UIViewController *)vc record:(PPHTransactionRecord *)record amount:(PPHAmount*)amount completionHandler:(void (^)(PPHTransactionResponse *record)) completionHandler;

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
-(void)provideSignature:(UIImage *)signature forTransaction:(PPHTransactionRecord *)previousTransaction completionHandler: (void (^)(PPHError *))completionHandler;


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
-(void)beginRefund:(PPHTransactionRecord*) previousTransaction forAmount: (PPHAmount*) amountOrNil completionHandler: (void(^)(PPHPaymentResponse*)) completionHandler;

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
-(void)sendReceipt:(PPHTransactionRecord*) previousTransaction toRecipient:(PPHReceiptDestination*)destination completionHandler: (PPHInvoiceBasicCompletionHandler) completionHandler;

@end
