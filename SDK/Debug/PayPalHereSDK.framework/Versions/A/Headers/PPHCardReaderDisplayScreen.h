//
//  PPHCardReaderDisplay.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 1/7/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * PPHCardReaderDisplay represents LED display screen capabilities of a card reader device.
 * Please query this object for more detailed information on the current card reader's
 * display screen. This object will be nil if the current card reader does not have a display
 */
@interface PPHCardReaderDisplayScreen : NSObject

/*!
 * Indicates whether the CardReaderDisplay has a backlight or not. Set to true if it does,
 * false otherwise.
 */
@property (nonatomic, readonly) BOOL backLightPresent;

/*!
 * Query the width and height variables of this CGSize struct to get resolution dimensions
 * of the card reader LED screen. If width and height are 0 this means resolution information
 * could not be determined.
 */
@property (nonatomic, readonly) CGSize resolutionDimensions;

@end
