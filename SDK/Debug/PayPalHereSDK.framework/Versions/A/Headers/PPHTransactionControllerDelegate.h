//
//  PPHTransactionControllerDelegate.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 1/8/14.
//  Copyright (c) 2014 PayPal. All rights reserved.
//
#import <Foundation/Foundation.h>

#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#endif

#import "PPHInvoiceConstants.h"
#import "PPHPaymentConstants.h"

@class PPHTransactionControllerWatcher;
@class PPHInvoice;
@class PPHSDKReceiptContext;

/*!
 * Actions the EMVSDK should take in the event of a contactless timeout.
 */
typedef NS_ENUM(NSInteger, PPHContactlessTimeoutAction) {
    /*! 
     * In the event of a contactless timeout, use this value to indicate you would like
     * the EMVSDK to take over and retry a contactless transaction.
     */
    ePPHContactlessTimeoutActionContinueWithContactless,
    /*!
     * In the event of a contactless timeout, use this value to indicate you would like
     * the EMVSDK to take over and resume with a contact transaction.
     */
    ePPHContactlessTimeoutActionContinueWithContact,
    /*!
     * In the event of a contactless timeout, use this value to indicate the EMVSDK
     * should simply cancel. This is the default behavior of the EMVSDK in a timeout scenario.
     */
    ePPHContactlessTimeoutActionCancelTransaction
};


typedef void (^PPHContactlessListenerTimeoutHandler) (PPHContactlessTimeoutAction timeoutOptions);

/**
 * The TransactionController defines an interface that can be used by the application to install a callback
 * object that is used to customize behavior and the payment experience.
 * TransactionControllers are set on the TransactionManager on a per transaction basis. Unlike persistent
 * listeners that are registered with the manager object, TransactionControllers are "forgotten" by the
 * SDK at the end of each transaction (regardless of success or failure).
 * TransactionControllers are also used to call out important transaction related events to the app
 * such as contactless payment listener timeouts.
 */
@protocol PPHTransactionControllerDelegate <NSObject>

/*!
 * This delegate method will be called by the EMVSDK whenever a user selects a payment method by
 * presenting their card. Mandatory if your app would like to take custom action such as handling tips
 * before letting the EMVSDK continue. Gives you a chance to modify the transaction total.
 * @param paymentOption the type of payment option the user selected.
 */
- (void)userDidSelectPaymentMethod:(PPHPaymentMethod) paymentOption;

/*!
 * This delegate method will be called by the EMVSDK whenever a user selects a refund method by 
 * presenting their card. Mandatory if your app would like to take custom action before letting
 * the EMVSDK continue. Gives you a chance to modify the transaction total.
 * @param refundOption the type of refund payment option user selected.
 */
- (void)userDidSelectRefundMethod:(PPHPaymentMethod) refundOption;

/*!
 * Mandatory if you are using the EMVSDK. Returns a reference to a 
 * navigation controller we drive UI off of.
 */
- (UINavigationController *)getCurrentNavigationController;

@optional

/*!
 * Custom receipt options we display as part of the EMVSDK receipt screen.
 */
- (NSArray *)getReceiptOptions;

/*!
 * This message is sent to the delegate right before the receipt options screen appears.
 * If your app does automatic receipt printing, this is a good place to do it.
 *
 * @param receiptContext: An object containing information about the transaction record & receipt status.
 */
- (void)receiptOptionsWillAppearWithContext:(PPHSDKReceiptContext *)receiptContext;

/*!
 * After starting a contactless transaction, if no contactless card is presented to the terminal a 
 * timeout occurs. Implement this method if you want to handle this scenario as the calling application.
 * If implemented, it is your responsibility to invoke the completionHandler to give control back to the
 * EMVSDK when ready. You will notify the EMVSDK of the action it must take.
 *
 * @param completionHandler: A completion handler that should be invoked by the receiving delegate.
 */
- (void)contactlessListenerDidTimeout:(PPHContactlessListenerTimeoutHandler) completionHandler;

/*!
 * Gets called when the reader has been activated for payments and is ready to process card present data. 
 * Handle any non-EMV SDK related processing once this comes back.
 */
- (void)readerDidActivateForPayments;

/*!
 * Gets called when the reader has been de-activated for payments. 
 * We have not dropped connection with the reader, but our reader will not process any card present data.
 * To enable the reader for payments again, just call activateReaderForPayments when you are ready and take 
 * a payment against the current TM invoice, or simply start a new transaction.
 * Deactivation can occur if a user presses cancel on the terminal before presenting their card to the terminal. 
 * Deactivation can also occur if you have explicitly called deActivateReaderForPayment.
 */
- (void)readerDidDeactivateForPayments;

@end
