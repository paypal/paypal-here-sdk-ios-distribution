//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PayPalHereSDK/PPHReaderType.h>
#import <PayPalHereSDK/PPHCardReaderDelegate.h>
#import <PayPalHereSDK/PPHCardReaderWatcher.h>
#import <PayPalHereSDK/PPHCardReaderMetadata.h>
#import <PayPalHereSDK/PPHInvoiceProtocol.h>

typedef NS_OPTIONS(NSInteger, PPHReaderError) {
    ePPHReaderErrorNone = 0,
    ePPHReaderErrorAudioAccessDenied = 1,
    ePPHReaderErrorLocationNotAvailable = 2,
    ePPHReaderErrorConnectFailed = 3,
    /*!
     * A request to use the reader was made but there was either no reader available or
     * active.
     */
    ePPHReaderErrorNotAvailable = 4
};

@class PPHChipAndPinDecisionEvent;
@class PPHChipAndPinAuthResponse;
@class PPHError;
@class PPHCardReaderBasicInformation;

/*!
 * The card reader manager handles all interaction with card and chip&pin hardware devices.
 * This includes audio readers, dock port readers, and Bluetooth readers.
 */
@interface PPHCardReaderManager : NSObject

/*!
 * Monitor for all known device types
 */
-(PPHReaderError)beginMonitoring;

/*!
 * Begin monitoring the device for connection and removal of the specified reader types.
 *
 * PLEASE NOTE that we will call EAAccessoryManager::register/unregisterForLocalNotifications
 * based on whether you pass the bluetooth or feature port reader types. So if your application is
 * ALSO manipulating the accessory framework, you should pass one of those types if you don't want
 * us to shutoff accessory notifications for your app. Alternatively, you can call endMonitoring first
 * and then beginMonitoring with your new types. This is obviously an edge case since you will likely
 * just call beginMonitoring once and be done with it.
 * @param readerTypes the types of readers to watch for
 */
-(PPHReaderError)beginMonitoring: (PPHReaderTypeMask) readerTypes;

/*!
 * Stop reacting to events around device connection and removal.
 * @param unregisterForLocalNotifications if YES, we will call EAAccessoryManager unregisterForLocalNotifications
 */
-(void)endMonitoring: (BOOL) unregisterForLocalNotifications;

/*!
 * Connect or activate the reader given. In the case of the audio readers, this may activate the battery,
 * in other cases this will connect to the bluetooth or feature port accessory or do similar activities.
 * @param reader The reader to activate.
 */
-(PPHReaderError)activateReader: (PPHCardReaderBasicInformation*) reader;

/*!
 * Disconnect or deactivate the reader given. In the case of the audior readers this may turn off the battery
 * or stop feeding power via the audio jack. In the case of bluetooth or feature port readers this may
 * disconnect the reader.
 * @param reader The reader to deactivate.
 */
-(void)deactivateReader: (PPHCardReaderBasicInformation*) reader;

/*!
 * Setup the card reader to process a transaction with an amount in a currency. For non-chip and pin
 * readers this isn't necessary, but if you want to support those readers,
 * you must call this method when you know the final amount that will be charged.
 * @param transaction the invoice containing the amount and currency information that will be charged
 */
-(PPHReaderError)beginTransaction: (id<PPHInvoiceProtocol>) transaction;

/*!
 * Once a transaction is complete, either via our processing services or out-of-band processing
 * such as cash or non-PayPal mechanisms, call endTransaction to shut down the reader. Since
 * some readers are battery powered, you should call this as soon as reasonable. The SDK will
 * automatically take care of this when your app is suspended or interrupted.
 */
-(void)endTransaction;

/*!
 * For Chip & Pin cards with multiple applications, you must select one
 * in response to the ePPHChipAndPinEventDecisionRequired event in order
 * to proceed.
 * @param event the original decision event from the reader
 * @param index the index of the selected application
 */
-(void)selectApplication: (PPHChipAndPinDecisionEvent*) event atIndex: (NSInteger) index;

/*!
 * For Chip & Pin cards, after the initial auth is done with the PayPal servers, the response
 * must be sent to the terminal for further processing. A card reader event (approve/decline)
 * will typically be fired shortly after, and the result of that should be passed to
 * finalizeChipAndPinTransaction.
 * @param response the response received from the PayPal servers
 */
-(void)continueTransaction: (PPHChipAndPinAuthResponse*) response;

/*!
 * For accessory based readers, there is the possibility that multiple capable devices may
 * be connected to the phone at the same time. In this case, specifying a preference
 * order can be useful to manage multiple devices with multiple phones. Generally, 
 * you're probably better off using the inherent iOS pairing screens to manage this,
 * but to each their own.
 *
 * @param arrayOfCardReaderBasicInfo The array argument should be a set of card reader 
 * information with as much information as relevant
 * filled out (for example name is not required when devices of that type have no name)
 */
-(void)setPreferenceOrder: (NSArray*) arrayOfCardReaderBasicInfo;

/*!
 * An array of known available devices. For example with bluetooth devices this will include
 * paired devices that are currently within range/connectable.
 *
 * @returns NSArray(PPHCardReaderBasicInformation)
 */
-(NSArray*) availableDevices;

/*!
 * In the case of readers requiring further setup, call this method with the PPHCardReaderBasicInformation
 * for the target reader. The error will be nil if it worked, else will tell you what went wrong.
 * @param reader the reader to upgrade
 * @param completionHandler called when the upgrade succeeds or fails
 */
-(void)beginUpgrade: (PPHCardReaderBasicInformation*) reader completionHandler: (void (^)(PPHError *error)) completionHandler;

@end
