//
//  RUACommand.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/9/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//
#import <Foundation/Foundation.h>

#ifndef ROAMreaderUnifiedAPI_RUACommand_h
#define ROAMreaderUnifiedAPI_RUACommand_h

#ifndef NS_ENUM
#define NS_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif
/** @enum RUACommand
 Enumeration of the commands supported by RUA
 */

typedef NS_ENUM (NSInteger, RUACommand) {

    /**
     * This command returns the device's current battery status
     */
    RUACommandBatteryInfo = 0,

    /**
     * This command returns the current KSN
     */
    RUACommandRetrieveKSN = 1,

    /**
     * Resets reader to initial default state.
     */
    RUACommandResetDevice = 2,

    /**
     * Returns a list of a hardware and software versions strings for RP750x and RP350x and just returns the firmware version for G4x.
     */
    RUACommandReadVersion = 3,

    /**
     * Provides details of the reader hardware and software capabilities in terms of the devices it supports (e.g. a smart card reader, display, etc.).<br>
     */
    RUACommandReadCapabilities = 4,

    /**
     * Waits until data from a magnetic card is read or a timeout expires.
     */
    RUACommandWaitForMagneticCardSwipe = 5,

    /**
     * Stops the reader from waiting for magnetic card swipe
     */
    RUACommandStopWaitingForMagneticCardSwipe = 6,

    /**
     * Stops the reader from waiting for card swipe
     */
    RUACommandCancelWait = 7,

    RUACommandEncryptedDataStatus = 8,

    /**
     * This command applies only to EMV readers.<br>
     * This command will add a number of AIDs to the list that the reader maintains, defining which applications are supported.<br>
     * The RP350x and RP750x readers can support a maximum of 20 contact AIDs and 20 contact-less AIDs.
     */
    RUACommandSubmitAIDsList = 9,

    /**
     * This command applies only to EMV readers.<br>
     * This command clears both the contact and contact-less AIDs lists stored on the reader and all contact-less application-specific data will be deleted.
     */
    RUACommandClearAIDsList = 10,

    /**
     * This command applies only to EMV readers.<br>
     * This command adds Certificate Authority public key to the public key data store that the reader maintains.<br>
     * This public key data store is used for both contact ICC and contact-less transactions.
     * The reader supports a maximum of 60 public keys.
     */
    RUACommandSubmitPublicKey = 11,

    /**
     * This command applies only to EMV readers.<br>
     * This commands revokes a Certificate Authority public key, by removing it from the public key data store.
     */
    RUACommandRevokePublicKey = 12,

    /**
     * This command applies only to EMV readers.<br>
     * This command clears public key data store in the reader.
     */
    RUACommandClearPublicKeys = 13,

    /**
     * This command applies only to EMV readers.<br>
     * This command is used to configure options relating to the user interface.
     */
    RUACommandConfigureUserInterfaceOptions = 14,

    /**
     * This command applies only to EMV readers.<br>
     * This command configures the reader amount DOLs, which determines the EMV TLV data returned in response of EMVStartTransaction command.
     */
    RUACommandConfigureAmountDOLData = 15,

    /**
     * This command applies only to EMV readers.<br>
     * This command configures the reader online DOLs, which determines the EMV TLV data returned in response of EMVTransactionData command.
     */
    RUACommandConfigureOnlineDOLData = 16,
    /**
     * This command applies only to EMV readers.<br>
     * This command configures the reader response DOLs, which determines the EMV TLV data returned in response of EMVCompleteTransaction command.
     */
    RUACommandConfigureResponseDOLData = 17,
    /**
     * This command applies only to EMV readers.<br>
     * This command is the starting point for all EMV transactions.<br>
     */
    RUACommandEMVStartTransaction = 18,
    /**
     * This command applies only to EMV readers.<br>
     * This command is only relevant if the application selection flag has been set so that the external device handles application selection.<br>
     */
    RUACommandEMVFinalApplicationSelection = 19,
    /**
     * This command applies only to EMV readers.<br>
     * This command provides data that wasn't available at the start of the transaction
     */
    RUACommandEMVTransactionData = 20,
    /**
     * This command applies only to EMV readers.<br>
     * This command will only be called by the external device following online processing and will transmit any data received from the host during online processing.<br>
     */
    RUACommandEMVCompleteTransaction = 21,
    /**
     * This command applies only to EMV readers.<br>
     * This command will end the current transaction and can be called at any point in the EMV transaction flow.<br>
     */
    RUACommandEMVTransactionStop = 22,

    RUACommandDisplayControl = 23,

    RUACommandKeypadControl = 24,

    RUACommandLoadSessionKey = 25,

    RUACommandRawCommand = 26,

    RUACommandSubmitContactlessAIDs = 27,

    RUACommandConfigureContactlessResponseDOL = 28,

    RUACommandConfigureContactlessOnlineDOL = 29,

    /**
     * Makes the reader to generate a ëbeepí sound for given duration and frequency.
     */
    RUACommandGenerateBeep = 30,

    /**
     * This command applies only to RP750x.<br>
     * This command will enable contactless (NFC) on RP750x device.<br>
     */
    RUACommandEnableContactless = 31,

    /**
     * This command applies only to RP750x.<br>
     * This command will disable contactless (NFC) on RP750x device.<br>
     */
    RUACommandDisableContactless = 32,

    RUACommandFirmwareUpdate = 33,


    /**
     * This command applies only to RP750x.<br>
     */

    /**
     * This command applies only to RP750x.<br>
     * This command will return the statistics on RP750x device like number of sucessful and failed swipes etc.,.<br>
     */
    RUACommandDeviceStatistics = 34,

    RUACommandEnableFirmwareUpdateMode = 35,

    RUACommandConfigureContactlessTransaction = 36,

    RUACommandEnergySaverModeTime = 37,

    RUACommandShutDownModeTime = 38,

    /**
     * This command applies only to EMV readers with keypad & display.<br>
     * This command is used to collect card data (PAN, expiry date, CVC)
     * using the terminal's keypad and display.
     */
    RUACommandCollectKeyedCardData =39,


    /**
     * This command applies to EMV card readers.
     * This command will make the card reader wait until the card is fully removed or if the timeout expires before returning a response.

     */
    RUACommandWaitForCardRemoval =40,

    /**
     *  This command is used for RKI
     */
    RUACommandReadKeyMappingInformation = 41,

    /**
     * This command is used to read certificate file versions that is used to check if a RKI Injection is needed
     */
    RUACommandReadCertificateFilesVersion=42,

    /**
     *  This command is used to enable the RKI Mode before the injection process
     */
    RUACommandEnableRKIMode = 43,
    /**
     *  This command is used to trigger the RKI process
     */
    RUACommandTriggerRKI = 44,

    /**
    * This command applies only to EMV readers.<br>
    * This command will add a number of AIDs to the list that the reader maintains, defining which applications are supported.<br>
    */
    RUACommandSubmitAIDsWithTLVDataList = 45,

    /**
     * This command is used to set the Firmware Version String
     */
    RUACommandSetFirmwareVersionString = 46,

    /**
     * This command is used to get the Firmware Version String
     */
    RUACommandGetFirmwareVersionString = 47,

    /**
     * This command returns the device's current battery status and battery level
     */
    RUACommandBatteryInfoWithChargingStatus = 48,

    /**
     * This command is used to configure beeps
     */
    RUACommandConfigureBeep = 49,

    /**
     *  This command is used to Get the VAS Version
     */
    RUACommandGetVASVersion = 50,

    /**
     *  This command is used to get the count of VAS merchants
     */
    RUACommandGetVASMerchantCount = 51,

    /**
     *  This command is used to clear the VAS merchants
     */
    RUACommandClearVASMerchants = 52,

    /**
     *  This command is used to get VAS error message
     */
    RUACommandGetVASErrorMessage = 53,

    /**
     *  This command is used to activate VAS exchange message logs
     */
    RUACommandActivateVASExchangedMessageLog = 54,

    /**
     *  This command is used to deactivate VAS exchange message logs
     */
    RUACommandDeactivateVASExchangedMessageLog = 55,

    /**
     *  This command is used to get VAS exchange message logs
     */
    RUACommandGetVASExchangedMessageLog = 56,

    /**
     *  This command is used to enable VAS Mode
     */
    RUACommandEnableVASMode = 57,

    /**
     *  This command is used to get VAS Data
     */
    RUACommandGetVASData = 58,

    /**
     *  This command is used to enable VAS PLSE State
     */
    RUACommandEnableVASPLSEState = 59,

    /**
     *  This command is used to set VAS Unpredictable Number
     */
    RUACommandSetVASUnpredictableNumber = 60,

    /**
     *  This command is used to set VAS Application Version
     */
    RUACommandSetVASApplicationVersion = 61,

    /**
     *  This command is used to add VAS Merchant
     */
    RUACommandAddVASMerchant = 62,

    /**
     *  This command is used to enable VAS Mode for merchant
     */
    RUACommandEnableVASModeForMerchant = 63,

    /**
     *  This command is used to start VAS
     */
    RUACommandStartVAS = 64,

    /**
     * This command is used to get the checksum for firmware type
     */
    RUACommandGetFirmwareChecksum = 65,

    RUACommandUnknown = 99
};

#endif /* ifndef ROAMreaderUnifiedAPI_RUACommand_h */
