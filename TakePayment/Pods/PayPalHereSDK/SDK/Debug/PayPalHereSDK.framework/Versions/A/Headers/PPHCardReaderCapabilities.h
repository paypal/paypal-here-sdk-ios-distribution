//
//  PPHCardReaderCapabilities.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 1/7/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "PPHCardReaderDisplayScreen.h"
#import "PPHCardReaderKeyPad.h"
#import "PPHSupportedPaymentInterfaces.h"

/*!
 * PPHCardReaderCapabilities represents the different capabilities a connected
 * card reader device has such as whether the device accepts contactless payments,
 * has a keypad, has a display screen and etc. We determine this advanced information
 * upon connection to the card reader and present it as a queriable object.
 */
@interface PPHCardReaderCapabilities : NSObject

/*!
 * Information on the display screen capabilities of a card reader device. If the card reader
 * has no LED display screen the object returned will be nil.
 */
-(PPHCardReaderDisplayScreen *)display;

/*!
 * Detailed information on the keypad of a card reader device if the card reader supports it.
 * If a keypad is not present/unsupported the object returned will be nil.
 */
-(PPHCardReaderKeyPad *)inputKeyPad;

/*!
 * Detailed information on the different types of payment interfaces a card reader device contains.
 */
-(PPHSupportedPaymentInterfaces *)paymentCapabilities;

/*!
 * Indicates the presence of audio/sound beeper capabilities on the device.
 * Returns YES if an audio beeper is available, NO otherwise.
 */
-(BOOL)beeperPresent;

/*!
 * Indicates whether the card reader has a built in printer or not.
 * Returns YES if a built-in printer exists, NO otherwise.
 */
-(BOOL)builtInPrinter;

/*!
 * The dictionary returned contains any extra capabilities we determined the card reader has. Each key in the
 * the dictionary is a NSString representing a capability. Bound to each key is a value, this value is also
 * an NSString representing more information on the capability. If the value string is empty, this indicates
 * the capability is supported but no further details on the capability could be found. Nil returned if no
 * capabilities were discovered at all. You can process this info however you wish.. Suggestions would be for
 * tracking, logging, or just blind data dumping onto a text field.
 */
-(NSDictionary *)extraCapabilityInfo;

@end
