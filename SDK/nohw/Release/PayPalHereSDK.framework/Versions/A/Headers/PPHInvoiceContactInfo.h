//
//  PayPal Here
//
//  Copyright (c) 2012 PayPal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * A collection of information about a person or entity for the purposes
 * of invoicing - billing info, merchant info, shipping info, etc.
 */
@interface PPHInvoiceContactInfo : NSObject <
    NSCoding,
    NSCopying
>

/*!
 * The first name of the contact, if available
 */
@property (nonatomic,strong) NSString* firstName;
/*!
 * The last name of the contact, if available
 */
@property (nonatomic,strong) NSString* lastName;
/*!
 * The business name of the contact, if available
 */
@property (nonatomic,strong) NSString* businessName;
/*!
 * The phone number of the contact, if available
 */
@property (nonatomic,strong) NSString* phoneNumber;
/*!
 * The fax number, if available
 */
@property (nonatomic,strong) NSString* faxNumber;
/*!
 * The URL of the merchant website, if available
 */
@property (nonatomic,strong) NSString* website;
/*!
 * A custom value for use as you please, if available. Displayed to the buyer
 */
@property (nonatomic,strong) NSString* customValue;

/*!
 * The city of the contact, if available
 */
@property (nonatomic,strong) NSString* city;
/*!
 * The country code of the contact, if available
 */
@property (nonatomic,strong) NSString* countryCode;
/*!
 * Line 1 of the address of the contact, if available
 */
@property (nonatomic,strong) NSString* lineOne;
/*!
 * Line 2 of the address of the contact, if available
 */
@property (nonatomic,strong) NSString* lineTwo;
/*!
 * The Postal Code of the address of the contact, if available
 */
@property (nonatomic,strong) NSString* postalCode;
/*!
 * The tax id (VAT, ABN) of the contact, if available
 */
@property (nonatomic,strong) NSString* taxId;
/*!
 * The state of the address of the contact, if available
 */
@property (nonatomic,strong) NSString* state;

/*!
 * Initialize a PPHInvoiceContactInfo with a minimum valid address
 * @param countryCode the two letter ISO code
 * @param city the city
 * @param lineOne the first line of the address
 */
- (id)initWithCountryCode:(NSString*)countryCode city:(NSString*)city addressLineOne:(NSString*)lineOne;
/*!
 * YES if this contact info is valid - meaning either no address or a valid address basically.
 */
- (BOOL)isValidInfo;

/*!
 * Return the contact info as a dictionary suitable for the PayPal server
 */
-(NSDictionary *)asDictionary;
/*!
 * Initialize the contact info from a server-provided dictionary
 * @param representation server response or result of asDictionary
 */
-(id)initWithDictionary:(NSDictionary *)representation;

@end
