//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPHCardReaderMetadata;

/*!
 * Data received as the result of a successful swipe through the card reader
 */
@interface PPHCardSwipeData : NSObject

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
 * Parse raw track data for name, account number, etc.
 * @param track1AndOr2 whatever was received from the card reader
 */
-(BOOL)parseTracks:(NSString*)track1AndOr2;

/*!
 * The card reader on which the swipe occurred.
 */
@property (nonatomic,strong) PPHCardReaderMetadata *reader;

/*!
 * Return the swipe data as a dictionary suitable for submission to PayPal
 */
-(NSDictionary*) asDictionary;
@end
