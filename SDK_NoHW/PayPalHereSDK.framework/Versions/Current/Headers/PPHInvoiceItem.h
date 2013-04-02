//
//  PayPal Here
//
//  Copyright (c) 2012 PayPal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AvailabilityMacros.h>

@class SellableItem;

/*!
 * A line item on an invoice. Can be positive, negative, or zero total/unit price.
 * See https://cms.paypal.com/cms_content/US/en_US/files/developer/PP_InvoicingAPIGuide.pdf
 * for details on field length restrictions and formats.
 */
@interface PPHInvoiceItem : NSObject<
    NSCopying
>

/*!
 * An itemId for YOUR reference - this is not stored with the invoice on the server side. This id must
 * be unique amongst all the items on an invoice so that the quantity increment/decrement operators can
 * work.
 */
@property (strong,nonatomic,readonly) NSString* itemId;
/*!
 * The quantity of this item purchased, which can be fractional
 */
@property (strong,nonatomic,readonly) NSDecimalNumber* quantity;
/*!
 * The name of this item
 */
@property (strong,nonatomic,readonly) NSString* name;
/*!
 * A longer description for the item
 */
@property (strong,nonatomic,readonly) NSString* itemDescription;
/*!
 * Price per unit - can be negative or zero (and of course positive)
 */
@property (strong,nonatomic,readonly) NSDecimalNumber* unitPrice;
/*!
 * The tax rate for this item. Note that at the moment tax rules are not flexible on
 * the PayPal backend so our rounding and computation rules are also not flexibile.
 * One alternative is to use a line item for tax.
 */
@property (strong,nonatomic,readonly) NSDecimalNumber* taxRate;
/*!
 * The name of the tax rate for this item - limited to 6 characters (yikes)
 */
@property (strong,nonatomic,readonly) NSString* taxRateName;

/*!
 * Do NOT call the default initializer. You will be greeted with an NSInternalInconsistencyException.
 */
-(id)init UNAVAILABLE_ATTRIBUTE;

/*!
 * Return the item as a dictionary suitable for the invoice API
 */
-(NSDictionary *)asDictionary;
/*!
 * Create the item from a dictionary from the invoice API
 * @param representation The dictionary from the server
 */
-(id)initWithDictionary:(NSDictionary *)representation;

@end
