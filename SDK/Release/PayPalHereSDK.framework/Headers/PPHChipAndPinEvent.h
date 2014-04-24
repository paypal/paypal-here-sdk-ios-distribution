//
//  PayPalHereSDK
//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPHCardReaderMetadata;

typedef NS_ENUM(NSInteger, PPHChipAndPinEventType) {
    ePPHChipAndPinEventApproved = 1,
    ePPHChipAndPinEventDeclined = 2,
    ePPHChipAndPinEventAuthRequired = 3,
    ePPHChipAndPinEventFailed = 4,
    ePPHChipAndPinEventCancelled = 5,
    ePPHChipAndPinEventPinVerified = 6,
    ePPHChipAndPinEventPinIncorrect = 7,
    ePPHChipAndPinEventWaitingForPin = 8,
    ePPHChipAndPinEventPinBlocked = 9,
    ePPHChipAndPinEventPinDigitPressed = 10,
    ePPHChipAndPinEventCardBlocked = 11,
    ePPHChipAndPinEventCardInserted = 12,
    ePPHChipAndPinEventCardRemoved = 13,
    ePPHChipAndPinEventCardInvalid = 14,
    ePPHChipAndPinEventCardDeclined = 15,
    ePPHChipAndPinEventCardChipBroken = 16,
    ePPHChipAndPinEventDecisionRequired = 17,
};

/*!
 * Base class for all events fired from chip&pin readers
 */
@interface PPHChipAndPinEvent : NSObject
/*!
 * The type of event being reported. Note that all events implement descriptions, so this
 * can be very helpful in debugging and in turning this enum to a string.
 */
@property (nonatomic,readonly) PPHChipAndPinEventType eventType;

/*!
 * The card reader metadata associated with the event.
 */
@property (nonatomic,readonly) PPHCardReaderMetadata *reader;
@end

/*!
 * An event fired when there are multiple applications on the card
 * and the consumer/merchant must choose which one to use
 */
@interface PPHChipAndPinDecisionEvent : PPHChipAndPinEvent
/*! Number of applications available */
-(NSInteger)count;
/*! Name of the application at index ix
 * @param ix the index (0-based) */
-(NSString*)applicationNameAtIndex: (NSInteger) ix;
/*! Id of the application at index ix
 * @param ix the index (0-based) */
-(NSString*)applicationIdAtIndex: (NSInteger) ix;
@end

/*!
 * An event fired when a digit was pressed on the keypad
 */
@interface PPHChipAndPinDigitEvent : PPHChipAndPinEvent
/*! The number of digits that have been pressed */
@property (nonatomic,readonly) NSInteger digits;
@end

/*!
 * An event fired when the terminal has begun waiting for PIN entry
 */
@interface PPHChipAndPinWaitingForPinEvent : PPHChipAndPinDigitEvent
/*!
 * YES if failure on this attempt is likely to result in card being locked out
 */
@property (nonatomic,readonly) BOOL lastAttempt;
@end

/*!
 * An event fired when an incorrect pin has been entered
 */
@interface PPHChipAndPinPinIncorrectEvent : PPHChipAndPinEvent
/*!
 * YES if failure on the next attempt is likely to result in card being locked out
 */
@property (nonatomic,readonly) BOOL lastAttempt;
@end

/*!
 * A chip & pin event that includes terminal data aka EMV data
 */
@interface PPHChipAndPinEventWithEmv : PPHChipAndPinEvent
/*!
 * Opaque EMV data to be passed to PayPal services
 */
@property (nonatomic,strong,readonly) NSData *emvData;
/*!
 * The identifier of the terminal being used in the context of the EMV data
 */
@property (nonatomic,strong,readonly) NSString *terminalId;
@end

/*!
 * A request from the terminal to authorize the transaction with a server
 */
@interface PPHChipAndPinAuthEvent : PPHChipAndPinEventWithEmv
/*!
 * Whether the PIN has been verified in this transaction
 */
@property (nonatomic,readonly) BOOL pinVerified;

/*!
 * Whether PIN is present for this transaction. pinPresent indicates whether PIN was entered by the user and NOT whether
 * it was validated by the terminal
 */
 @property (nonatomic, readonly) BOOL pinPresent;

/*!
 * Whether the current card requires signature for transactions
 */
@property (nonatomic,readonly) BOOL signatureRequired;
/*!
 * The auth/reader serial number, which includes rotating keys for
 * servers to make sense of the EMV data for this transaction
 */
@property (nonatomic,readonly) NSString *serial;
@end

/*!
 * Fired when the transaction PIN entry is canceled by pressing
 * the cancel button or removing the card.
 */
@interface PPHChipAndPinCancelEvent : PPHChipAndPinEvent
/*!
 * Whether the card has been removed as well
 */
@property (nonatomic,readonly) BOOL cardRemoved;
@end

/*!
 * Fired when reading the EMV chip fails
 */
@interface PPHChipAndPinCardChipBrokenEvent : PPHChipAndPinEvent
/*!
 * Whether a fallback swipe is now enabled (either by repeated failures
 * or the configuration of the chip)
 */
@property (nonatomic,readonly) BOOL fallbackEnabled;
@end