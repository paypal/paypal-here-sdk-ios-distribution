//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PayPalHereSDK/PPHReaderType.h>

/*!
 * PPHCardReaderBasicInformation represents what can be determined about a connected
 * card reader device without actually connecting or talking to it.
 */
@interface PPHCardReaderBasicInformation : NSObject <NSCoding>
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
 * When specifying a preference order for readers, use the anyReader value at the
 * end of the list to allow a reader outside of the preference set to be chosen.
 */
+(PPHCardReaderBasicInformation*)anyReader;
@end

/*!
 * More complete information about a card reader which may not be available until
 * activity (such as a swipe) has occurred
 */
@interface PPHCardReaderMetadata : PPHCardReaderBasicInformation

/*!
 * A device-specific serial number that should not change for the same 
 * device and should not be the same for any other device with the same family.
 */
@property (nonatomic,strong) NSString *serialNumber;

/*!
 * The device software version, if available
 */
@property (nonatomic,strong) NSString *firmwareRevision;

/*!
 * If the device has a battery and supports reporting of
 * the battery level, this will be non-zero
 */
@property (nonatomic) NSInteger batteryLevel;

@end
