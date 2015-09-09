//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHReaderConstants.h"
#import "PPHCardReaderDelegate.h"
#import "PPHCardReaderWatcher.h"
#import "PPHCardReaderMetadata.h"
#import "PPHInvoiceProtocol.h"

typedef NS_OPTIONS(NSInteger, PPHReaderError) {
    ePPHReaderErrorNone = 0,
    ePPHReaderErrorAudioAccessDenied = 1,
    /*
     * The system does not have updated GPS location. Your application must obtain permission to monitor the user's
     * GPS location in order to transact with PayPal Here.
     */
    ePPHReaderErrorLocationNotAvailable = 2,
    ePPHReaderErrorConnectFailed = 3,
    /*!
     * A request to use the reader was made but there was either no reader available or
     * active.
     */
    ePPHReaderErrorNotAvailable = 4,
    /*!
     * The current transaction is not valid (no amount), or reader was mid-transaction and could not be started.
     */
    ePPHReaderErrorTransactionNotValid = 5,
    ePPHReaderErrorNonReaderConnected = 6,
    ePPHReaderErrorInvalidState = 7
};

@class PPHChipAndPinDecisionEvent;
@class PPHChipAndPinAuthResponse;
@class PPHError;
@class PPHCardReaderMetadata;

/*!
 * The card reader manager handles all interaction with card and chip&pin hardware devices.
 * This includes audio readers, dock port readers, and Bluetooth readers.
 *
 * Each reader goes through 5 states during it's lifecycle:
 *
 * Available - A potential reader of one of the monitored types has been detected.
 * Connecting - We are in the process of acquiring more information about the reader.
 * Connected - The reader is fully identified.
 * Open - The reader is listening for card data
 */
@interface PPHCardReaderManager : NSObject

/*!
 * Monitor for all known device types
 */
- (PPHReaderError)beginMonitoring;

/*!
 * Begin monitoring the device for connection and removal of the specified reader types.
 *
 * @param readerTypes the types of readers to watch for
 */
- (PPHReaderError)beginMonitoring: (PPHReaderTypeMask) readerTypes;

/*!
 * The types we are currently monitoring for.
 */
@property (nonatomic, readonly) PPHReaderTypeMask monitoringForTypes;

/*!
 * Stop reacting to events around device connection and removal.
 */
- (void)endMonitoring;

/*!
 * Mark the given reader as the active reader for transactions. Anytime there is only a single reader available
 * it will automatically become the active reader. Sending nil as the reader will deactivate the current active
 * reader.
 */
- (PPHReaderError)activateReader:(PPHCardReaderMetadata *)reader;

/*!
 * Begins listening for card data on the active reader. If the reader is not yet fully connected it will
 * automatically open when it's connection completes successfully. Has no effect if the reader is already
 * in an open state.
 *
 * @return wether or not the reader was opened or marked to be opened
 */
- (BOOL)openActiveReader;

/*!
 * Stops listening for card data on the active reader. Has no effect if the reader is not open.
 *
 * @return wether or not the reader was closed
 */
- (BOOL)closeActiveReader;

/*!
 * An array of known available devices. For example with bluetooth devices this will include
 * paired devices that are currently within range/connectable.
 *
 * @returns NSArray(PPHCardReaderMetadata)
 */
- (NSArray *)availableReaders;

/*!
 * Get the currently available reader of a given type. A reader is considered available if we have a potential
 * connection opportunity (e.g. something is inserted in the audio jack, or a bluetooth device with a matching 
 * protocol is in range)
 *
 * @param type the type of reader to get
 */
- (PPHCardReaderMetadata *)availableReaderOfType:(PPHReaderType)type;

/*!
 * The most recently available reader of a given type. If the reader type is currently available
 * then you will get the same return value as calling `availableReaderOfType`
 *
 * @param type the type of reader to get
 */
- (PPHCardReaderMetadata *)lastAvailableReaderOfType:(PPHReaderType)type;

/*!
 * Get the reader that is currently being used for transactions. If there is a single available reader then
 * it will automatically be marked as active. If there are multiple available readers you must call
 * `activateReader` to select one before transacting.
 */
- (PPHCardReaderMetadata *)activeReader;

/*!
 * Begin the flow that updates the reader.
 * @param reader The reader to begin upgrading
 * @param completionHandler called when the action has completed
 */
- (void)beginUpgradeUsingSDKUIForReader:(PPHCardReaderMetadata *)reader completionHandler:(void(^)(BOOL success, NSString *message))completionHandler;

@end
