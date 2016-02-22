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
#import "PPHTransactionRecord.h"

/*!
 * Actions the SDK should take in the event of a contactless timeout.
 */
typedef NS_ENUM(NSInteger, PPHContactlessTimeoutAction) {
    ePPHContactlessTimeoutActionContinueWithContactless,
    ePPHContactlessTimeoutActionContinueWithContact,
    ePPHContactlessTimeoutActionCancelTransaction
};




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
 * Request an NSArray of PPHReceiptOption from the delegate. This array represents
 * a series of options that will be displayed alongside the Email and SMS receipt options.
 * A sample use case for this is implementing a "Print" option that will print the receipt using
 * your custom hardware and logic.
 * See PPHReceiptOption for more information.
 */
- (NSArray *)getReceiptOptions;

/*!
 * This message is sent to the delegate right before the receipt options screen appears.
 * If your app does automatic receipt printing, this is a good place to do it.
 *
 * @param record A description of the current transaction
 */
- (void)receiptOptionsWillAppearForRecord:(PPHTransactionRecord *)record;

/*!
 * To conserve battery life the contactless listener of the reader may timeout, in which case this
 * method will be called so you may instruct the SDK to take a specific action. If this delegate
 * method is unimplemented the SDK will default to ePPHContactlessTimeoutActionCancelTransaction
 */
- (PPHContactlessTimeoutAction)contactlessTimeoutAction;

/*!
 * The user added a gratuity to PPHTransactionManager's currentInvoice through prompts on the reader
 *
 * @param invoice The invoice that was updated. The same instance that is the currentInvoice of PPHTransactionManager
 */
- (void)userAddedGratuityToInvoice:(PPHInvoice *)invoice;

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
