//
//  PayPalHereSDK
//
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * Receipts can be sent to email addresses or mobile phone numbers. At some point in the near future, you will also receive
 * "tokens" back from payment operations that allow you to send receipts to the email address or phone number on file for
 * the card.
 */
@interface PPHReceiptDestination : NSObject

/*!
 * The email address, phone number, or "tokenized" email/phone.
 */
@property (nonatomic,strong) NSString *destinationAddress;

/*!
 * YES if this destination is an email address, NO if it's a phone number
 */
@property (nonatomic,assign) BOOL isEmail;

@end
