//
//  PPHSupportedPaymentInterfaces.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 1/7/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHReaderPaymentInterfaces.h"
#import "PPHMagStripeTracks.h"

/*!
 * PPHSupportedPaymentInterfaces represents the different payment interfaces a card reader supports.
 * For example, if a card reader has a contactless payment interface, this means the card reader has
 * some hardware capabilities to process contactless payments. Query this object for more detailed 
 * information on the payment acceptance capabilities of the current reader.
 */
@interface PPHSupportedPaymentInterfaces : NSObject

/*!
 * All the different payment interfaces the card reader currently supports in the form of a 
 * bitmask. Please take a look at the public header PPHReaderPaymentInterfaces.h to understand the definition
 * of the bitmask. Each bit position represents a payment. If the mask is on/set at that bit, then the card
 * reader accepts that particular payment.
 */
@property (nonatomic, readonly) PPHSupportedPaymentInterfaceMask supportedPayments;

/*!
 * Convenience boolean to quickly let you know if the card reader accepst swipe based payments
 */
@property (nonatomic, readonly) BOOL swipe;

/*! 
 * Convenience boolean to quickly let you know if the card reader supports some form of contactless
 * payments. If you want more granular information on which flavor of contactless the reader supports 
 * please parse the bit mask
 */
@property (nonatomic, readonly) BOOL contactless;

/*!
 * Convenience boolean to let you know if the device supports EMV based chip and dip payments.
 */
@property (nonatomic, readonly) BOOL chipAndPinEMV;

/*!
 * Mask data to represent supported magStripe tracks on the current readers. Please take
 * a look at the public header PPHMagStripeTracks.h to read the mask.
 */
@property (nonatomic, readonly) PPHMagStripeTracksMask supportedTracks;

@end
