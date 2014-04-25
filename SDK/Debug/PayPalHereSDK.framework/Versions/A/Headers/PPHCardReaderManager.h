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
    ePPHReaderErrorTransactionNotValid = 5
};

typedef NS_ENUM(NSInteger, PPHEMVTransactionType) {
    ePPHEMVTransactionTypeInvalid,
    ePPHEMVTransactionTypeSale,
    ePPHEMVTransactionTypeRefund
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
 * @param readerOrNil The reader to activate or nil for the default/only reader.
 */
-(PPHReaderError)activateReader: (PPHCardReaderBasicInformation*) readerOrNil;

/*!
 * Disconnect or deactivate the reader given. In the case of the audior readers this may turn off the battery
 * or stop feeding power via the audio jack. In the case of bluetooth or feature port readers this may
 * disconnect the reader.
 * @param readerOrNil The reader to deactivate or nil for the default/only reader.
 */
-(void)deactivateReader: (PPHCardReaderBasicInformation*) readerOrNil;

/*!
 * For accessory based readers, there is the possibility that multiple capable devices may
 * be connected to the phone at the same time. In this case, specifying a preference
 * order can be useful to manage multiple devices with multiple phones. Generally, 
 * you're probably better off using the inherent iOS pairing screens to manage this,
 * but to each their own. In addition, if you have custom bluetooth or dock port readers
 * that we support, you can pass the custom protocol string in this list and we'll look for
 * that. IMPORTANT: You still need to add the protocol to your application's plist
 * (under supported accessories) in order for this to work.
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
 * for the target reader.
 * @param reader the reader to upgrade
 */
-(void)beginUpgrade: (PPHCardReaderBasicInformation*) reader;

@property (nonatomic,readonly) BOOL isInPinRetryMode;

@end
