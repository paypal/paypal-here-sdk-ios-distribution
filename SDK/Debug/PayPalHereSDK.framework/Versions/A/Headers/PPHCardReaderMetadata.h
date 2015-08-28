//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHReaderConstants.h"
#import "PPHCardReaderCapabilities.h"
#import "PPHReaderDisplayFormatter.h"
#import "PPHReaderBatteryMetadata.h"


/*!
 * PPHCardReaderMetadata represents what can be determined about a connected
 * card reader device without actually connecting or talking to it.
 */
@interface PPHCardReaderMetadata : NSObject <NSCoding>
/*!
 * When specifying a preference order for readers, use the anyReader value at the
 * end of the list to allow a reader outside of the preference set to be chosen.
 */
+(PPHCardReaderMetadata*)anyReader;

/*!
 * The type of reader this metadata is for
 */
@property (nonatomic,assign) PPHReaderType readerType;

/*!
 * The overall name for all instances this type of device
 */
@property (nonatomic,strong) NSString *family;

/*!
 * A friendly name for the device, if available
 */
@property (nonatomic,strong) NSString *friendlyName;

/*!
 * In the case of accessory readers (bluetooth, dock port), this is the protocol used
 * by the device
 */
@property (nonatomic,strong) NSString *protocolName;

/*!
 * A device specific model number as a string that should never change for the same device
 */
@property (nonatomic, strong) NSString *modelNo;

/*!
 * The credit card processing device reader model which should never change
 */
@property (nonatomic, assign) PPHReaderModel readerModel;
                              
/*!
 * A device-specific serial number that should not change for the same 
 * device and should not be the same for any other device with the same family.
 */
@property (nonatomic,strong) NSString *serialNumber;

/*!
 * The device OS version, if available
 */
@property (nonatomic,strong) NSString *osRevision;

/*!
 * The device software version, if available
 */
@property (nonatomic,strong) NSString *firmwareRevision;

/*!
 * Metadata on the battery of this reader, such as whether 
 * it is charging and the batterys current charge level.
 */
@property (nonatomic, strong) PPHReaderBatteryMetadata *batteryInfo;

/*!
 * More complete information on the capabilities of the card reader device. Such as
 * the different forms of payments it accepts and etc..
 * If no capability information can be determined this object returned will be nil.
 */
-(PPHCardReaderCapabilities *)capabilities;

/*!
 * Is there a card currently dipped in the reader?
 */
- (BOOL)cardIsInserted;

/*!
 * Is the device prepared to take a transaction
 */
- (BOOL)isReadyToTransact;

/*!
 * Is there a software update available for the reader?
 */
- (BOOL)upgradeIsAvailable;

/*!
 * Are the upgrade files downloaded and ready to be applied?
 */
- (BOOL)upgradeIsReady;

/*!
 * Does the reader need to upgraded before taking a payment?
 */
- (BOOL)upgradeIsManadatory;

/*!
 * Does the available upgrade contain the initial setup of the reader?
 */
- (BOOL)upgradeIsInitialSetup;

/*!
 * Is the battery level low enough to warrant warning the user?
 */
- (BOOL)batteryIsLow;

/*!
 * Is the battery level too low to take a payment?
 */
- (BOOL)batteryIsCritical;

/*!
 * Is the battery too low to start a reader upgrade?
 */
- (BOOL)isReadyForUpgrade;

/*!
 * Is the battery currently charging?
 */
- (BOOL)batteryIsCharging;

@end
