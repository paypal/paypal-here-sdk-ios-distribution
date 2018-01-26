//
//  RUAConfigurationManager.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/9/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "RUADevice.h"
#import "RUADeviceResponseHandler.h"
#import "RUAApplicationIdentifier.h"
#import "RUAPublicKey.h"
#import "RUADisplayControl.h"
#import "RUAKeypadControl.h"
#import "RUAFirmwareType.h"
#import "RUAFirmwareChecksumType.h"

@protocol RUAConfigurationManager <NSObject>

/**
 This methods activates the roam device passed. <br>
 <br>
 This method is required only for devices that have Bluetooth interface or both audio jack and Bluetooth interfaces.<br>
 For G4x and RP350x where the reader has only one interface (audio jack), the audio jack interface gets activated. <br>
 @param device the roam device object
 @return true, if successful
 @see RUADevice
 */
- (BOOL)activateDevice:(RUADevice *)device;

/**
 This is an Asynchronous method that sends the clear AIDS command to the device. <br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)clearAIDSList:(OnProgress)progress response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the clear public keys command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)clearPublicKeys:(OnProgress)progress response:(OnResponse)response;


/**
 This is an Asynchronous method that sends the generate beep command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)generateBeep:(OnProgress)progress response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the reader capabilities control to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)getReaderCapabilities:(OnProgress)progress response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the read version command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)readVersion:(OnProgress)progress response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the read key mapping command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)readKeyMapping:(OnProgress)progress response:(OnResponse)response;
/**
 This is an Asynchronous method that sends the reset device command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)resetDevice:(OnProgress)progress response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the retrieve KSN command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)retrieveKSN:(OnProgress)progress response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the Revoke public key command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param publicKey the public key
 @param response OnResponse block
 @param progress OnProgress block
 
 @see PublicKey
 */
- (void)revokePublicKey:(RUAPublicKey *)key progress:(OnProgress)progress response:(OnResponse)response;


/**
 This is an Asynchronous method that sets the transaction amount data object list<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param list list of the data object list parameters (reader parameters)
 @param response OnResponse block
 @param progress OnProgress block
 @see RUAParameter */
- (void)setAmountDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response;

/**
 This is an synchronous method that sets the expected transaction amount data object list<br>
 <br>
 This call is used to set up the expected amount DOL format for data parsing, and shall not be used to issue any command
 to the reader.<br>
 @param list list of the data object list parameters (reader parameters)
 @see RUAParameter */
- (void)setExpectedAmountDOL:(NSArray *)list;

/**
 Sets the command timeout value on the reader.
 @param timeout  timeout value in seconds
 */
- (void)setCommandTimeout:(int)timeout;

/**
 This is an Asynchronous method that sets the transaction online data object list<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param list list of the data object list parameters (reader parameters)
 @param response OnResponse block
 @param progress OnProgress block
 
 @see RUAParameter
 */
- (void)setOnlineDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response;

/**
 This is an synchronous method that sets the expected transaction online data object list<br>
 <br>
 This call is used to set up the expected online DOL format for data parsing, and shall not be used to issue any command
 to the reader. <br>
 @param list list of the data object list parameters (reader parameters)
 @see RUAParameter */
- (void)setExpectedOnlineDOL:(NSArray *)list;

/**
 This is an Asynchronous method that sets the transaction response data object list<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param list list of the data object list parameters (reader parameters)
 @param response OnResponse block
 @see RUAParameter@param response OnResponse block
 */
- (void)setResponseDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response;

/**
 This is an synchronous method that sets the expected transaction response data object list<br>
 <br>
 This call is used to set up the expected response DOL format for data parsing, and shall not be used to issue any command
 to the reader. <br>
 @param list list of the data object list parameters (reader parameters)
 @see RUAParameter */
- (void)setExpectedResponseDOL:(NSArray *)list;

/**
 This is an Asynchronous method that sets the user Interface Options for the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param response OnResponse block
 @param progress OnProgress block
 
 */
- (void)setUserInterfaceOptions:(OnProgress)progress response:(OnResponse)response;

/**
 This command is used to configure options related to the card holder user interface.
 <br>
 @param cardInsertionTimeout timeout period
 @param merchantLanguageCode
 @param pinPadOptions refer to the table below for format of this field, <br>
 <table> <tbody>
 <tr><td>b7</td><td>b6</td><td>b5</td><td>b4</td><td>b3</td><td>b2</td><td>b1</td><td>b0</td><td>Meaning</td></tr>
 <tr><td>x</td><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td>RFU</td></tr>
 <tr><td></td><td>1</td><td></td><td></td><td></td><td></td><td></td><td></td><td>Ignore ICC inserts when ICC is disabled in the EMV Start Transaction P2 field.</td></tr>
 <tr><td></td><td></td><td>1</td><td></td><td></td><td></td><td></td><td></td><td>Enable Enhanced Contactless Display Control</td></tr>
 <tr><td></td><td></td><td></td><td>1</td><td></td><td></td><td></td><td></td><td>Disable PIN-Pad Exception Handling</td></tr>
 <tr><td></td><td></td><td></td><td></td><td>1</td><td></td><td></td><td></td><td>Display “PIN Tries Exceeded” after last PIN failure</td></tr>
 <tr><td></td><td></td><td></td><td></td><td></td><td>1</td><td></td><td></td><td>Enable cardholder to confirm cancellation</td></tr>
 <tr><td></td><td></td><td></td><td></td><td></td><td></td><td>1</td><td></td><td>Disable PIN-Pad progress screens</td></tr>
 <tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td><td>1</td><td>Enable Call Card Issuer message</td></tr>
 </tbody></table>
 @param backlightControl 0 for manual control over the backlight which can be controlled by using the Level 1 Display Control command. <br>
                         1 for automatic control which will switch the backlight on at the start of an EMVL2 transaction and off at the end.<br>
 @param response OnResponse block
 @param progress OnProgress block
 */
- (void) setUserInterfaceOptions:(int) cardInsertionTimeout
         withDefaultLanguageCode:(RUALanguageCode)languageCode
               withPinPadOptions:(Byte) pinPadOptions
            withBackLightControl:(Byte) backlightControl
                        progress:(OnProgress)progress
                        response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the Submit aid list command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br><br>
 @param applicationIdentifiers the list of application identifiers <br>
        FloorLimit,CVMLimit,TxnLimit,TermCaps and TLVData are only applicable for contactless application identifiers <br>
        those properties are not valid for contact application identifiers <br>
 @param response OnResponse block
 @param progress OnProgress block
 @see ApplicationIdentifier
 */
- (void)submitAIDList:(NSArray *)aids progress:(OnProgress)progress response:(OnResponse)response;

/** This is an Asynchronous method that sends the Submit aid list command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to the callback method onResponse on the DeviceResponseHandler passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br><br>
 @param applicationIdentifiers
            the list of application identifiers,<br>Application Identifier must contain TLVData.<br>
 @param response OnResponse block
 @see ApplicationIdentifier
*/
- (void)submitAIDWithTLVDataList:(NSArray*) applicationIdentifiers response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the Submit public key command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param publicKey the public key
 @param response OnResponse block
 @param progress OnProgress block
 @see RUAPublicKey
 */
- (void)submitPublicKey:(RUAPublicKey *)publicKey progress:(OnProgress)progress response:(OnResponse)response;

/**
 This is an Asynchronous method that sends the command string as it is to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param rawCommand command string
 @param response OnResponse block
 @param progress OnProgress block
 */
- (void)sendRawCommand:(NSString *)rawCommand progress:(OnProgress)progress response:(OnResponse)response;

/**
 Returns display control of the roam device.
 @return RUADisplayControl display control
 @see RUADisplayControl
 */

- (id <RUADisplayControl> )getDisplayControl;

/**
 Returns the certificate file versions of the connected device.
 @param response OnResponse block
 @param progress OnProgress block
 */

- (void)readCertificateFilesVersion:(OnProgress)progress response:(OnResponse)response ;


/**
 Returns keypad control of the roam device.
 @return RUAKeypadControl keypad control
 @see RUAKeypadControl
 */

- (id <RUAKeypadControl> )getKeypadControl;

/***
 This command stores a single or double length master or session key specified in a secure memory location with the position specified by the session key locator.
 Session keys are decrypted prior to being stored using the master key corresponding to the specified master key locator.
 
 @param keyLength 0 for single length key and 1 for double length key
 @param sessionKeyLocator
 @param masterKeyLocator
 @param encryptedKey
 @param ID An ID stored in the Pinpad that can be used to identify the decryption key on the host side. If no ID needs to be specified, this value must be set ‘00000000’.
 @param rawCommand command string
 @param response OnResponse block
 @param progress OnProgress block
 */
- (void) loadSessionKey:(int) keyLength
                        withSessionKeyLocator: (NSString *) sessionKeyLocator
                        withMasterKeyLocator: (NSString *) masterKeyLocator
                        withEncryptedKey:(NSString *) encryptedKey
                        withCheckValue: (NSString *) checkValue
                        withId:(NSString *) ID
                        response:(OnResponse)response;

/**
 This is an Asynchronous method that sets contactless transaction response data object list<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param list list of the data object list parameters (reader parameters)
 @param response OnResponse block
 @see RUAParameter@param response OnResponse block
 */
- (void)setContactlessResponseDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response;

/**
 This is a synchronous method that sets the expected contactless transaction response data object list<br>
 <br>
 This call is used to set up the expected response DOL format for data parsing, and shall not be used to issue any command
 to the reader. <br>
 @param list list of the data object list parameters (reader parameters)
 @see RUAParameter */
- (void)setExpectedContactlessResponseDOL:(NSArray *)list;

/**
 This is an Asynchronous method that sets the contactless transaction online data object list<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param list list of the data object list parameters (reader parameters)
 @param response OnResponse block
 @see RUAParameter@param response OnResponse block
 */
- (void)setContactlessOnlineDOL:(NSArray *)list progress:(OnProgress)progress response:(OnResponse)response;

/**
 This is a synchronous method that sets the expected contactless transaction online data object list<br>
 <br>
 This call is used to set up the expected response DOL format for data parsing, and shall not be used to issue any command
 to the reader. <br>
 @param list list of the data object list parameters (reader parameters)
 @see RUAParameter */
- (void)setExpectedContactlessOnlineDOL:(NSArray *)list;


/**
 This is an Asynchronous method that sends the Submit contactless aid list command to the reader.<br>
 <br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br><br>
 @param applicationIdentifiers the list of application identifiers
 @param response OnResponse block
 @param progress OnProgress block
 @see ApplicationIdentifier
 */
- (void)submitContactlessAIDList:(NSArray *)aids progress:(OnProgress)progress response:(OnResponse)response;

/**
 This method enables the contactless (turns on NFC card reader on the device) <br>
 @param response OnResponse block
*/
- (void) enableContactless:(OnResponse)response;

/**
 This method enables RKI mode for RKI Injection process <br>
 @param response OnResponse block
 */
- (void) enableRKIMode:(OnResponse)response;


/**
 *  This methos does the RKI Injection process
 *
 *  @param groupName      refers to the groupName of the device to do RKI Injection
 *  @param response        OnResponse block
 */
- (void) triggerRKIWithGroupName:(NSString *) groupName response:(OnResponse)response;

/**
 This method disables the contactless (turns OFF NFC card reader on the device) <br>
 @param response OnResponse block
 */
- (void) disableContactless:(OnResponse)response;

/**
 This method configures the contactless transaction options on the reader <br>
 @param response OnResponse block
 */
- (void) configureContactlessTransactionOptions: (BOOL) supportCVM
                                    supportAMEX: (BOOL) supportAMEX
                             enableCryptogram17: (BOOL) enableCryptogram17
                         enableOnlineCryptogram: (BOOL) enableOnlineCryptogram
                                   enableOnline: (BOOL) enableOnline
                                enableMagStripe: (BOOL) enableMagStripe
                                  enableMagChip: (BOOL) enableMagChip
                                    enableQVSDC: (BOOL) enableQVSDC
                                      enableMSD: (BOOL) enableMSD
                                  enableDPASEMV: (BOOL) enableDPASEMV
                                  enableDPASMSR: (BOOL) enableDPASMSR
                  contactlessOutcomeDisplayTime: (int) contactlessOutcomeDisplayTime
                                       response: (OnResponse) response;

/**
 This method configures the contactless transaction options on the reader <br>
 @param response OnResponse block
 */

- (void) configureContactlessTransactionOptions: (BOOL) supportCVM
									supportAMEX: (BOOL) supportAMEX
							 enableCryptogram17: (BOOL) enableCryptogram17
						 enableOnlineCryptogram: (BOOL) enableOnlineCryptogram
								   enableOnline: (BOOL) enableOnline
								enableMagStripe: (BOOL) enableMagStripe
								  enableMagChip: (BOOL) enableMagChip
									enableQVSDC: (BOOL) enableQVSDC
									  enableMSD: (BOOL) enableMSD
				  contactlessOutcomeDisplayTime: (int) contactlessOutcomeDisplayTime
                                       response: (OnResponse) response __deprecated;

/**
 * This is an Asynchronous method that sets the energy saver mode timer
 * @param seconds
 * @param response OnResponse block
 */

- (void)setEnergySaverModeTime:(int)seconds res:(OnResponse)response;

/**
 * This is an Asynchronous method that sets the shut down mode timer
 * @param seconds
 * @param response OnResponse block
 */


- (void)setShutDownModeTime:(int)seconds res:(OnResponse)response;

/**
 * This is a Asynchronous method that sets the custom firmware version<br>
 * <br>
 * @param firmwareType enum to describe the type firmware that needs to be set
 * @param version string which holds the value of the firmware type.
 * @param response OnResponse block
 * @see RUAFirmwareType
 * When the reader processes the command, it returns the result as a map to the OnResponse block passed.<br>
 */
- (void)setFirmwareType:(RUAFirmwareType)firmwareType withVersion:(NSString*)version response:(OnResponse)response;

/**
 * This is a Asynchronous method that gets the custom firmware version<br>
 * <br>
 * @param firmwareType enum to describe the type firmware that needs to be returned
 * @param response OnResponse block
 * @see RUAFirmwareType
 * When the reader processes the command, it returns the result as a map to the OnResponse block passed.<br>
 */
- (void)getFirmwareVersionStringForType:(RUAFirmwareType)firmwareType response:(OnResponse)response;

/**
 * This is a Asynchronous method that is used to configure the beeps<br>
 * <br>
 * @param readMagneticCardBeep BOOL describes, if reader should disable beep at when ready to read Magnetic Card data
 * @param removeCardBeep BOOL describes, if reader should disable beep when card is ready to be removed
 * @param EMVStartTransactionBeep BOOL describes, if reader should disable beep when ready to start EMV transaction
 * @param response OnResponse block
 * When the reader processes the command, it returns the result as a map to the OnResponse block passed.<br>
 */
- (void)configureReadMagneticCardBeep:(BOOL)disableReadMagneticCardBeep
                       removeCardBeep:(BOOL)disableRemoveCardBeep
           andEMVStartTransactionBeep:(BOOL)disableEMVStartTransactionBeep
                             response:(OnResponse)response;

/**
 * This is a Asynchronous method that is used to get the checksum<br>
 * <br>
 * @param type RUAFirmwareChecksumType enum to describe the firmwaretype
 * @param response OnResponse block
 */
-(void)getChecksumForType:(RUAFirmwareChecksumType)type response:(OnResponse)response;

@end
