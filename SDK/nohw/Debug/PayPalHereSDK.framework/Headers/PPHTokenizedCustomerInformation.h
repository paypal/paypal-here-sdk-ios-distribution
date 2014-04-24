//
//  PPHTokenizedCustomerInformation.h
//  PayPalHereSDK
//
//  Created by Metral, Max on 11/26/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * PayPal card processing returns some extremely useful data for receipts and/or loyalty programs. (Checkin has this stuff built in)
 */
@interface PPHTokenizedCustomerInformation : NSObject

/**
 * An opaque identifier for this card which is distinct from any customerId from checkin and unique across cards for a particular merchant.
 */
@property (nonatomic, strong) NSString *customerId;

/**
 * If availble, a masked email address for confirmation of identity or display for receipt destination.
 */
@property (nonatomic, strong) NSString *maskedEmailAddress;

/**
 * If availble, a masked mobile phone number for confirmation of identity or display for receipt destination.
 */
@property (nonatomic, strong) NSString *maskedMobileNumber;

/**
 * A token to be provided to the server to send a receipt to the saved destination or to associate an email address with this card
 * for future transactions.
 */
@property (nonatomic, strong) NSString *receiptPreferenceToken;

@end
