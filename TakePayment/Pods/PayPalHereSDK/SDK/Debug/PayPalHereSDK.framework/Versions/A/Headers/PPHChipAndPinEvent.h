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
    ePPHChipAndPinEventButtonPressed = 10,
    ePPHChipAndPinEventCardBlocked = 11,
    ePPHChipAndPinEventCardInserted = 12,
    ePPHChipAndPinEventCardRemoved = 13,
    ePPHChipAndPinEventCardInvalid = 14,
    ePPHChipAndPinEventCardDeclined = 15,
    ePPHChipAndPinEventCardChipBroken = 16,
    ePPHChipAndPinEventDecisionRequired = 17,
    ePPHChipAndPinEventCardTapped = 18,
    ePPHChipAndPinEventCardTapFailure = 19,
    ePPHChipAndPinEventNumericEntry = 20
};

typedef NS_ENUM(NSInteger, PPHCardTapError) {
    ePPHCardTapErrorUnknown,                // Error returned could not be determined
    ePPHCardTapErrorHardwareFailure,        // Error resulted from a hardware failure during transaction
    ePPHCardTapErrorChipCardInserted,       // Error because a chip card was inserted, contactless aborted
    ePPHCardTapErrorMSDCardSwiped,          // Error because a card was swiped, contactless aborted
    ePPHCardTapErrorContactlessTimeout,     // Error from contactless listener timeout
    ePPHCardTapErrorICCRequested,           // Error contactless EMV card is requesting to be inserted
    ePPHCardTapErrorInsertSwipeOrTapNewCard // Error tap failed, terminal requesting to insert, swipe, or tap a different card
};

typedef NS_ENUM(NSInteger, PPHChipAndPinButtonType) {
    ePPHChipAndPinButtonUnknown,         // Unknown could not determine which button was pressed
    ePPHChipAndPinButtonKeyPadDigit,     // A key pad digit was pressed
    ePPHChipAndPinButtonBack,            // Back button was pressed
    ePPHChipAndPinButtonCancel,          // Cancel Button pressed
    ePPHChipAndPinButtonOK               // OK check Button pressed
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
@interface PPHChipAndPinButtonPressedEvent : PPHChipAndPinEvent
/*! num digits that were pressed */
@property (nonatomic,readonly) NSInteger digits;
/*! The type of button that was pressed */
@property (nonatomic, readonly) PPHChipAndPinButtonType pressedButton;
@end

/*!
 * An event fired when the terminal has begun waiting for PIN entry
 */
@interface PPHChipAndPinWaitingForPinEvent : PPHChipAndPinButtonPressedEvent
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

/*!
 * Fired when reading of a contactless tap card fails
 */
@interface PPHChipAndPinCardTapFailureEvent : PPHChipAndPinEvent
/*!
 * The exact error returned from the terminal when attempting
 * to process a tap. This error will indicate why the failure
 * occurred.
 */
@property (nonatomic,readonly) PPHCardTapError tapError;
@end

/*!
 * Fired when succesfully reading a contactless tap
 */
@interface PPHChipAndPinCardTappedEvent : PPHChipAndPinEvent
/*!
 * The type of tap we have received.
 */
@property (nonatomic,assign) PPHContactlessTransactionType tapType;
@end

@interface PPHChipAndPinNumericEntryEvent : PPHChipAndPinEvent
/*!
 * The number entered by the user
 */
@property (nonatomic,readonly) NSDecimalNumber *number;
@end
