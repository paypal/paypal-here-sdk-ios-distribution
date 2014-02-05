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

/**
 * The TransactionController defines an interface that can be used by the application to install a callback
 * object that is used to customize behavior.
 * TransactionControllers are set on the TransactionManager on a per transaction basis. Unlike persistent
 * listeners that are registered with the manager object, TransactionControllers are "forgotten" by the
 * SDK at the end of each transaction (regardless of success or failure).
 * TransactionControllers interact with the SDK by using the TransactionControlAction and also via the parameters
 * passed into the callbacks. For example, the value HANDLED indicates that the application has taken over processing
 * and that the SDK should stop processing this particular transaction at this state.
 * The CONTINUE flag indicates that the application has either made changes to the input object or left everything untouched
 * and that the SDK should continue processing the transaction.
 *
 */
@class PPHTransactionControllerWatcher;
@class PPHInvoice;

/*!
 * The Payment Events we'll send to the app.  These are currently a simple enum.
 */
typedef NS_ENUM(NSInteger, PPHTransactionControlActionType) {
    /*!
     * Use this return value to indicate that the application has taken over transaction
     */
    ePPHTransactionType_Handled,
    /*!
     * Use this value to indicate that the SDK should continue with the transaction 
     */
    ePPHTransactionType_Continue
};

@protocol PPHTransactionControllerDelegate <NSObject>

/*!
 * onPreAuthorize This callback is invoked by the TransactionManager in response to a call to
 * the processPayment() API in the TransactionManager. As soon as the TransactionManager is ready
 * to perform the authorization this callback is invoked. The SDK is responsible for ensuring that
 * this call is invoked in the appropriate thread.
 *
 * @param inv This is the Invoice object against which the authorization will be performed. At this point
 *            the application can choose to make some changes to the invoice. For example, a tip could
 *            be added to an Invoice at this time or an item could be removed etc.
 *
 * @param preAuthJSON A dictionary ready for json conversion and shipment to the paypal service
 *                      that represents the request payload. This is the request data that will
 *                      be sent to the backend and the application is allowed to modify this data.
 * CAUTION: Modifying the data incorrectly could cause your transaction to fail. Ensure that any changes by the app
 *          will not introduce errors and that you handle the error cases appropriately. More documentation on what
 *          the server expects in the payload can be found in the documentation.
 *
 * @return TransactionControlAction. Return HANDLED if you want the SDK to stop processing the transaction at this point
 * If HANDLED is returned, then the Transaction will be canceled but the application is free to keep the invoice around
 * if it so wishes. If the invoice is not required then use the cancel method defined on the Invoice to cancel it.
 * Return CONTINUE if you wish the SDK to continue processing this transaction.
 *
 */
-(PPHTransactionControlActionType)onPreAuthorizeForInvoice:(PPHInvoice *)inv withPreAuthJSON:(NSMutableDictionary*) preAuthJSON;

/*!
 * onPostAuthorize 
 * 
 * This callback is invoked by the TransactionManager once authorization is complete. Note that authorization
 * complete does not indicate success. The input parameter indicates whether or not the authorization failed.
 *
 * @param didFail - indicates whether the authorization failed. A true indicates that the authorization itself failed. A false indicates
 *                that the authorization did not fail. It however, DOES NOT indicate that the transaction was successful.
 *
 */
-(void)onPostAuthorize:(BOOL)didFail;

@end
