//
//  PPHCardReaderKeyPad.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 1/7/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * PPHCardReaderKeyPad represents a card reader keypad. If the card reader device does not have
 * a keypad, this object will be nil. Query this object for more detailed information on the keypad
 */
@interface PPHCardReaderKeyPad : NSObject

/*!
 * Indicates whether the card reader keypad has a backlight or not.
 */
@property (nonatomic, readonly) BOOL backLightPresent;

@end
