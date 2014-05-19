//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#ifndef PayPalHereSDK_PPHCardReaderDelegate_h
#define PayPalHereSDK_PPHCardReaderDelegate_h

#import "PPHReaderType.h"

@class PPHCardSwipeData;
@class PPHCardReaderMetadata;
@class PPHChipAndPinEvent;
@class PPHCardReaderBasicInformation;

/*!
 * Basic events for audio, feature port, and EMV readers. While methods are marked optional for cases where you
 * just want to see certain events (like reader software upgrade), the delegate that's actually looking to complete
 * a payment is going to need all of these.
 */
@protocol PPHSimpleCardReaderDelegate <NSObject>

@optional

/*!
 * This event will be triggered in cases where reader detection takes a while, such as for
 * the audio readers. It presents an opportunity to show UI indicating that you are "working on it"
 * @param reader the basic information about reader that is actively being "verified"
 */
-(void)didStartReaderDetection: (PPHCardReaderBasicInformation*) reader;

/*!
 * A fully working reader was detected and is available
 * @param reader the reader that was detected
 */
-(void)didDetectReaderDevice: (PPHCardReaderBasicInformation*) reader;

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
 * Serial number and other related information is available for the card reader.
 * @param metadata the available data about the reader
 */
-(void)didReceiveCardReaderMetadata: (PPHCardReaderMetadata*) metadata;

@end

/*!
 * Additional events for EMV aka Chip & Pin readers
 */
@protocol PPHCardReaderDelegate <PPHSimpleCardReaderDelegate>

@optional

/*!
 * Certain reader types are field upgradeable with things like keys and software updates. If you get this message, you will
 * NOT receive didDetectReaderDevice until the condition is resolved.
 * @param reader the reader that has an available upgrade
 * @param message the reason or explanation for the upgrade
 * @param required whether the reader can proceed without an upgrade
 * @param initial whether this is the initial upgrade to the reader
 * @param estimatedDuration the estimated time the update will take to apply in total
 */
-(void)didDetectUpgradeableReader: (PPHCardReaderBasicInformation*) reader withMessage: (NSString*) message isRequired: (BOOL) required isInitial: (BOOL) initial withEstimatedDuration: (NSTimeInterval) estimatedDuration;

/*!
 * The pending reader upgrade has been prepared this includes downloading necessary files and doing any other work
 * to pave the way for a successful upgrade. This signals that the upgrade is ready to be applied.
 */
-(void)didFinishUpgradePreparations;

/*!
 * A reader upgrade was successful
 * @param successful whether the upgrade succeeded
 * @param message Additional details about the upgrade (if it failed)
 */
-(void)didUpgradeReader: (BOOL) successful withMessage: (NSString*) message;

/*!
 * There is a status update to the current ongoing reader upgrade
 * @param message Details about the current upgrade status
 * @param currentStep The number of the current upgrade step from 1 to totalSteps
 * @param totalSteps The total number of steps in the upgrade
 * @param completion The progress of the upgrade from 0.0 to 1.0
 */
-(void)didReceiveReaderUpgradeStatusWithMessage: (NSString*) message currentStep: (NSInteger) currentStep totalSteps: (NSInteger) totalSteps completion: (float) completion;

/*!
 * Called when an event related to chip & pin transactions has occurred on the reader
 * @param event the event that has occurred
 */
-(void)didReceiveChipAndPinEvent: (PPHChipAndPinEvent*) event;

@end



#endif
