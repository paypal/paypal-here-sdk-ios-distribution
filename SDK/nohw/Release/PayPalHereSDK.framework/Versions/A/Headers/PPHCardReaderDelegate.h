//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#ifndef PayPalHereSDK_PPHCardReaderDelegate_h
#define PayPalHereSDK_PPHCardReaderDelegate_h

#import "PPHReaderConstants.h"

@class PPHCardSwipeData;
@class PPHCardReaderMetadata;
@class PPHChipAndPinEvent;
@class PPHCardReaderMetadata;

/*!
 * Basic events for audio, feature port, and EMV readers. While methods are marked optional for cases where you
 * just want to see certain events (like reader software upgrade), the delegate that's actually looking to complete
 * a payment is going to need all of these.
 */
@protocol PPHCardReaderDelegate <NSObject>

@optional

/*!
 * A potential reader has been found.
 * @param reader the reader that was found
 */
-(void)didFindAvailableReaderDevice: (PPHCardReaderMetadata*) reader;

/*!
 * This event will be triggered in cases where reader detection takes a while, such as for
 * the audio readers. It presents an opportunity to show UI indicating that you are "working on it"
 * @param reader the basic information about reader that is actively being "verified"
 */
-(void)didStartReaderDetection: (PPHCardReaderMetadata*) reader;

/*!
 * A fully working reader was detected and is available
 * @param reader the reader that was detected
 */
-(void)didDetectReaderDevice: (PPHCardReaderMetadata*) reader;

/*!
 * A reader device has been removed from the system
 * @param readerType the type of reader that was removed
 */
-(void)didRemoveReader: (PPHReaderType) readerType;

/*!
 * Something has occurred in the read head of the reader. Since processing can take a second or so,
 * this allows you to get some UI up. Be careful how much work you do here because taxing the CPU
 * will hurt success rate.
 */
-(void)didDetectCardSwipeAttempt;

/*!
 * A card swipe has succeeded
 * @param card Encrypted and masked data about the card
 */
-(void)didCompleteCardSwipe:(PPHCardSwipeData*)card;

/*!
 * A swipe attempt failed. Usually this means the magstripe could not be read and the merchant should try again.
 */
-(void)didFailToReadCard;

/*!
 * New or different information has been discovered about a reader and we have produced an updated metadata.
 * @param metadata the available data about the reader
 */
-(void)didReceiveCardReaderMetadata: (PPHCardReaderMetadata*) metadata;

/*!
 * A new reader has been set as active and is now the only one eligible for payment.
 * @param previousReader the reader that was active
 * @param currentReader the reader that is active
 */
-(void)activeReaderChangedFrom: (PPHCardReaderMetadata*) previousReader to: (PPHCardReaderMetadata*) currentReader;

/*!
 * A reader upgrade was successful
 * @param successful whether the upgrade succeeded
 * @param message Additional details about the upgrade (if it failed)
 */
-(void)didUpgradeReader: (BOOL) successful withMessage: (NSString*) message;


/*!
 * Called when a card is that was inserted into the reader has been removed.
 */
-(void)didRemoveCard;

@end



#endif
