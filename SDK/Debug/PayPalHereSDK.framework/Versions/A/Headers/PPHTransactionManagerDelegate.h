//
//  PPHTransactionManagerDelegate.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 6/11/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHCardReaderMetadata.h"

@class PPHTransactionManager;

/**
 * The Payment Events we'll send to the app.  These are currently a simple enum.
 */
typedef NS_ENUM(NSInteger, PPHTransactionEventType) {
    /*!
     * The TransactionManager has entered the idle state.  It is not doing any work and is ready to begin a payment or refund.
     */
    ePPHTransactionType_Idle,
    /*!
     * The transactionManager has entered a state of data collection.  beginPayment() has been called and we <br>
     * are currently collecting information from card readers or the application.  You can now set/modify the invoice,
     * signatures, and other data related to this payment.
     */
    ePPHTransactionType_GettingPaymentInfo,
    
    /*!
     * This event will be triggered in cases where reader detection takes a while, such as for
     * the audio readers. It presents an opportunity to show UI indicating that you are "working on it"
     */
    ePPHTransactionType_DidStartReaderDetection,
    
    /*!
     * A fully working reader was detected and is available
     */
    ePPHTransactionType_DidDetectReaderDevice,
    
    /*!
     * A reader device has been removed from the system
     */
    ePPHTransactionType_DidRemoveReader,
    
    /*!
     * Something has occurred in the read head of the reader. Since processing can take a second or so,
     * this allows you to get some UI up. Be careful how much work you do here because taxing the CPU
     * will hurt success rate.
     */
    ePPHTransactionType_CardReadBegun,
    
    /*!
     * Card data received. The transaction manager has received card data, and it can be processed
     */
    ePPHTransactionType_CardDataReceived,

    /*!
     * Card data received. The transaction manager has received card data, but it is not allowed to process it
     */
    ePPHTransactionType_ReadCardNotAllowed,
    
    /*!
     * A swipe attempt failed. Usually this means the magstripe could not be read and the merchant should try again.
     */
    ePPHTransactionType_FailedToReadCard,
    
    /*!
     * The TransactionManager has entered a state where it is communicating with the backend servers to collect a payment.
     * It is now too late to cancel the payment.
     */
    ePPHTransactionType_ProcessingPayment,
    
    /*!
     * The TransactionManager has entered a state where it has completed the transaction successfully and is
     * waiting for the app to collect a signature from the customer and call the finalizePayment API.
     */
    ePPHTransactionType_WaitingForSignature,
    
    /*!
     * Event specifying that transaction has been cancelled. This will happen only in case of EMV Payments when te user pulls 
     * the card out of the reader when transaction is going on
     */
    ePPHTransactionType_TransactionCancelled,
    
    /*!
     * Event specifying that transaction has been declined. This will happen only in case of EMV Payments in case terminal 
     * declines the transaction for some reason.
     */
    ePPHTransactionType_TransactionDeclined,
    
    /*!
     * Refund type selection has been cancelled.
     */
    ePPHTransactionType_RefundTypeSelectionCancelled
};

/**
 * PaymentEvent
 *
 * Currently only provides the event type.  Could be expanded in the future to include
 * additional information about the payment event.
 */
@interface PPHTransactionManagerEvent : NSObject

/*! The type of event that occurred */
@property (nonatomic) PPHTransactionEventType eventType;

/*! The reader relevant to the event if applicable */
@property (nonatomic, strong) PPHCardReaderMetadata *reader;

@end

/*!
 * The PPHTransactionManagerDelegate aids in communicating with the application layer by sending various 
 * messages throughout the payment flow. These messages reflect the different stages of a transaction
 * and could be used by the application to display appropriate text, image or UI on the screen.
 */
@protocol PPHTransactionManagerDelegate <NSObject>

/**
 * onPaymentEvent
 *
 * This method will be called whenever the payment manager needs to communicate a payment
 * related event to the application.
 *
 * @param event : A PaymentEvent object the contains information about the event.
 */
- (void)onPaymentEvent:(PPHTransactionManagerEvent *) event;

@end

