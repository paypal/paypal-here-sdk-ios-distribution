//
//  PPHTransactionManagerDelegate.h
//  PayPalHereSDK
//
//  Created by Angelini, Dom on 6/11/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

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
     * Card data received.  The transaction manager has received card data.
     */
    ePPHTransactionType_CardDataReceived,
    
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
    ePPHTransactionType_TransactionDeclined
    
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

@end

@protocol PPHTransactionManagerDelegate <NSObject>

/**
 * onPaymentEvent
 *
 * This method will be called whenever the payment manager needs to communicate a payment
 * related event to the application.
 *
 * @param e a PaymentEvent object the contains information about the event.
 */
- (void)onPaymentEvent:(PPHTransactionManagerEvent *) event;

@end

