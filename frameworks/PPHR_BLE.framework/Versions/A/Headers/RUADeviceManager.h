//
//  Reader.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/9/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RUAProgressHandler.h"
#import "RUATransactionManager.h"
#import "RUAConfigurationManager.h"
#import "RUADeviceManager.h"
#import "RUADeviceStatusHandler.h"
#import "RUAReleaseHandler.h"
#import "RUADeviceSearchListener.h"
#import "RUAAudioJackPairingListener.h"

#ifndef RUADeviceManager_h
#define RUADeviceManager_h

typedef  enum {
	RUADeviceTypeG4x,
	RUADeviceTypeRP350x,
    RUADeviceTypeMOBY3000,
    RUADeviceTypeRP450c,
	RUADeviceTypeRP750x,
    RUADeviceTypeRP45BT,
    RUADeviceTypeMOBY8500,
	RUADeviceTypeUnknown
}RUADeviceType;

/**
 The Device Manager interface manages all the interactions with the roam device.
 */

@protocol RUADeviceManager <NSObject>

/**
 Returns transaction manager of the roam device.
 @return RUATransactionManager reader configuration manager
 @see RUATransactionManager
 */

- (id <RUATransactionManager> )getTransactionManager;

/**
 Returns configuration manager of the roam device.
 @return RUAConfigurationManager reader configuration manager
 @see RUAConfigurationManager
 */
- (id <RUAConfigurationManager> )getConfigurationManager;

/**
 Returns the Device type
 @return RUADeviceType enumeration of the roam device type
 @see RUADeviceType
 */

- (RUADeviceType)getType;

/**
 Initializes the roam reader (through audio jack or bluetooth) and registers the status handler for device status updates.
 <p>
 Usage:
 <code>
 <br>
 id<Reader> mRP750xReader;
 id<RUADeviceStatusHandler> mRUADeviceStatusHandler;
 [mRP750xReader initialize:mRUADeviceStatusHandler];
 </code>
 </p>
 @param statusHandler the roam reader  status handler
 @see RUADeviceStatusHandler
 @return true if successful
 */
- (BOOL)initializeDevice:(id <RUADeviceStatusHandler> )statusHandler;

/**
 Initializes the roam reader (through audio jack or bluetooth) with defined timeout and registers the status handler for device status updates.
 <p>
 Usage:
 <code>
 <br>
 id<Reader> mRP750xReader;
 id<RUADeviceStatusHandler> mRUADeviceStatusHandler;
 [mRP750xReader initialize:mRUADeviceStatusHandler andTimeout:30*1000];
 </code>
 </p>
 @param statusHandler the roam reader  status handler
 @param timeout defined timeout in millisecond(Default 30 seconds)
 @see RUADeviceStatusHandler
 @return true if successful
 */
- (BOOL)initializeDevice:(id <RUADeviceStatusHandler> )statusHandler andTimeout:(int)timeout;

/**
 * Registers the handler to receive progress updates
 * @param progressHandler the handler that receives progress updates
 * @see RUAProgressHandler
 */
- (void)registerProgressHandler:(id<RUAProgressHandler>)handler;

/**
 * Unregisters the handler to stop receiving progress updates
 * @param progressHandler the handler that receives progress updates
 * @see RUAProgressHandler
 */
- (void)unregisterProgressHandler:(id<RUAProgressHandler>)handler;

/**
 Checks if the payment device is ready.
 *
 @return true if payment device is active
 */
- (BOOL)isReady;

/**
 Releases the roam reader and triggers status handler (passed to the initialize method) onDisconnected call back method if successful.
 *
 @return true if successful
 */
- (BOOL)releaseDevice;


/**
 Releases the roam reader and triggers status handler (passed to the initialize method) onDisconnected call back method if successful.
 @param releaseHandler release handler
 */
- (void)releaseDevice:(id <RUAReleaseHandler>)releaseHandler;

/**
 Cancels any pending connection attempt to reader by sending a stop command.
 */
-(void)stopInitialization;

/**
 Discovers the available devices for duration
 *
 @param searchListener the callback handler
 @duration duration of the bluetooth discovery in milliseconds
 @see RUADeviceSearchListener
 */
- (void)searchDevicesForDuration:(long)duration andListener:(id <RUADeviceSearchListener> )searchListener;

/**
 Discovers the available devices
 *
 @param searchListener the callback handler
 @see RUADeviceSearchListener
 */
- (void)searchDevices:(id <RUADeviceSearchListener> )searchListener;

/**
 Discovers the available devices with lowRSSI and highRSSI<br>
 <br>
 RSSI stands for Received Signal Strength Indicator.<br>
 It is the strength of the beacon's signal as seen on the receiving device, e.g. a smartphone.<br>
 The signal strength depends on distance and Broadcasting Power value.<br>
 At maximum Broadcasting Power (+4 dBm) the RSSI ranges from -26 (a few inches) to -100 (40-50 m distance).<br>
 @param lowRSSI lowest RSSI
 @param highRSSI highest RSSI
 @param searchListener the callback handler
 @see RUADeviceSearchListener
 */
- (void)searchDevicesWithLowRSSI:(NSInteger)lowRSSI andHighRSSI:(NSInteger)highRSSI andListener:(id<RUADeviceSearchListener>)searchListener;

/**
 Stops the ongoing discovery process
 */
- (void)cancelSearch;

/**
 This is an Asynchronous method that returns the battery level of a device. <br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameter, RUAParameterBatteryLevel<br>
 @param response OnResponse block
 */
- (void)getBatteryStatus:(OnResponse)response;

/**
 This is an Asynchronous method that returns the battery level and charging status of a device. <br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, 
 RUAParameterBatteryLevel,
 RUAParameterIsDeviceCharging<br>
 @param response OnResponse block
 */
- (void)getBatteryLevelWithChargingStatus:(OnResponse)response;

/**
 Asynchronous method that sets the card reader in firmware update mode

 @param response OnResponse block
*/
- (void) enableFirmwareUpdateMode:(OnResponse)response;

/**
Triggers the firmware update with the file path provided and returns the response on the handler passed
@param firmwareFilePath
 @param response OnResponse block
*/
- (void) updateFirmware:(NSString *) firmareFilePath progress:(OnProgress)progress response:(OnResponse)response;

/**
 Synchronous method that will cancel the firmware update process and force the reader to exit the firmware update mode
 */
- (void) cancelFirmwareUpdate;


/**
 This is an Asynchronous method that returns the statistics of a device, like the count of total number of swipes, bad swipes etc., 
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.
 The map passed to the onResponse callback contains the following parameters as keys, 
	RUAParameterSystemCountPowerON,
	RUAParameterSystemCountKeyHit,
	RUAParameterSystemCountTotalSwipes,
	RUAParameterSystemCountAudioJackInsertions,
	RUAParameterSystemCountUSBEvent,
	RUAParameterSystemCountBadSwipes,
	RUAParameterSystemCountFallbackSwipes,
	RUAParameterSystemCountChipInsertions,
	RUAParameterSystemCountPowerOnFailForChipCards,
	RUAParameterSystemCountAPDUFailForChipCards,
	RUAParameterSystemCountRFWupa,
	RUAParameterSystemCountClessActivateFail,
	RUAParameterSystemCountClessAPDUFail,
	RUAParameterSystemCountCharges,
	RUAParameterSystemCountBluetoothConnectionsLost,
	RUAParameterSystemCountOutOfBattery,
	RUAParameterSystemCountCompleteCharge,
	RUAParameterSystemCountCommands
 @param response OnResponse block
 */
- (void) getDeviceStatistics:(OnResponse)response;


/**
 * Asynchronous method that will start the process of pairing with
 * a Bluetooth card reader that doesn't have a keypad or display.
 * Currently only theRP450c.
 * <br>
 * @param ctx
 * @param pairListener
 *            , see {@link AudioJackPairingListener}
 */
- (void) requestPairing:(id <RUAAudioJackPairingListener> ) pairListener;

/**
 * Asynchronous method that will complete the process of pairing with
 * a Bluetooth card reader that doesn't have a keypad or display.
 * <br>
 * Calling this method outside of
 * {@link AudioJackPairingListener.onPairConfirm } has no effect.
 * <br>
 * Currently only supported by the RP450c device manager.
 */
- (void) confirmPairing:(BOOL)isMatching __deprecated;

/**
 * Returns the active communication type for those devices that can have multiple interfaces
 * connected at a point of time. E.g RP450c that is plugged in via audio jack and can have active
 * bluetooth connection.
 * @return {@see RUACommunicationInterface}
 */

-(RUACommunicationInterface) getActiveCommunicationType;

@end

#endif
