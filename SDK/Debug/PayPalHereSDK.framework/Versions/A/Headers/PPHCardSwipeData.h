//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHCardEnums.h"

@class PPHCardReaderMetadata;

/*!
 * Data received as the result of a successful swipe through the card reader
 */
@interface PPHCardSwipeData : NSObject

/*!
 * Initialize card swipe data from a non-PayPalHere compatible card reader.
 * @param track1 The data from track1, if any
 * @param track2 The data from track2, if any
 * @param serial The serial number of the reader
 * @param readerType the type of reader, such as MAGTEK, ROAM or MIURA_(SWIPE|FB_SWIPE)
 * @param extraInfo Any extra information necessary to interpret and process the track data, such as
 * ksn (key serial number)
 */
-(id)initWithTrack1: (NSString*) track1 track2: (NSString*) track2 readerSerial: (NSString*) serial withType: (NSString*) readerType andExtraInfo: (NSDictionary*) extraInfo;

/*!
 * The masked card number, if available. Usually includes first four and last four
 */
@property (nonatomic,strong) NSString *maskedCardNumber;

/*!
 * If any name was available, this will be non-nil. Sometimes the name is pre-parsed into first
 * and last name, so those fields may or may not be filled out.
 */
@property (nonatomic,strong) NSString *cardholderName;

/*!
 * IF AVAILABLE, the parsed first name.
 */
@property (nonatomic,strong) NSString *cardholderFirstName;
/*!
 * IF AVAILABLE, the parsed last name.
 */
@property (nonatomic,strong) NSString *cardholderLastName;

/*!
 * The month of card expiration, 1-12
 */
@property (nonatomic) NSInteger expirationMonth;
/*!
 * The full year of the card expiration, e.g. 2012
 */
@property (nonatomic) NSInteger expirationYear;

/*!
 * Any extra data from the card reader to go along with the swipe
 */
@property (nonatomic,strong) NSDictionary *extraData;

/*!
 * Set this property to YES before beginning payment is we have, or will collect a signature
 * for this payment. Beginning a payment with a signature will automatically set this value to YES.
 */
@property (nonatomic) BOOL signaturePresent;

/*!
 * Parse raw track data for name, account number, etc.
 * @param track1AndOr2 whatever was received from the card reader
 */
-(BOOL)parseTracks:(NSString*)track1AndOr2;

/*!
 * The card reader on which the swipe occurred.
 */
@property (nonatomic,strong) PPHCardReaderMetadata *reader;

/*!
 * Return the cardType
 */
@property (nonatomic, readonly) PPHCreditCardType cardType;

/*!
 * Return the swipe data as a dictionary suitable for submission to PayPal
 */
-(NSDictionary*) asDictionary;
@end
