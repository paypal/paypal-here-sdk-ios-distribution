//
//  PayPal Here
//
//  Copyright (c) 2012 PayPal, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPHInvoice;
@class PPHAmount;

typedef enum {
    // Components
    ePPHTotalIncludeNone =         0,
    ePPHTotalIncludeItems =        1<<0,
    ePPHTotalIncludeTax =          1<<1,
    ePPHTotalIncludeDiscount =     1<<2,
    ePPHTotalIncludeGratuity =     1<<3,
    ePPHTotalIncludeShipping =     1<<4,
    ePPHTotalIncludeShippingTax =  1<<5,
    ePPHTotalIncludeRefund =       1<<6,
    ePPHTotalIncludeCustomAmount = 1<<7,
    
    // Convenience
    ePPHTotalSimpleTotal =  ePPHTotalIncludeItems | ePPHTotalIncludeTax,
    ePPHTotalGrandTotal =  ePPHTotalIncludeItems | ePPHTotalIncludeTax | ePPHTotalIncludeDiscount | ePPHTotalIncludeGratuity | ePPHTotalIncludeShipping | ePPHTotalIncludeShippingTax | ePPHTotalIncludeCustomAmount,
    ePPHTotalTaxTotal = ePPHTotalIncludeTax | ePPHTotalIncludeShippingTax,
    ePPHTotalGrandTotalInclusive =  ePPHTotalIncludeItems | ePPHTotalIncludeDiscount | ePPHTotalIncludeGratuity | ePPHTotalIncludeShipping | ePPHTotalIncludeShippingTax | ePPHTotalIncludeCustomAmount,
} PPHInvoiceTotalParts;

/*!
 * A class to help with all the different ways one computes the totals of an invoice
 */
@interface PPHInvoiceTotals : NSObject

/*!
 * The honest to goodness total that is expected to be paid against this invoice.
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *total;
/*!
 * Total before taxes, discounts and tips
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *subTotal;
/*!
 * Tax from the items
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *itemTaxTotal;
/*!
 * Item tax + shipping tax
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *taxTotal;
/*!
 * Total of discounts on the order
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *discountsTotal;
/*!
 * Tip added to the order
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *gratuityTotal;
/*!
 * Shipping charge (not common for in person transactions obviously)
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *shippingTotal;
/*!
 * Refunds against this invoice, only relevant when read from the server
 */
@property (nonatomic,strong,readonly) NSDecimalNumber *refundTotal;
/*!
 * Details for each tax rate on this order
 */
@property (nonatomic,strong,readonly) NSDictionary *taxDetails;

/*! Initialize and compute totals for an invoice
 * @param invoice The invoice on which to compute totals
 */
- (id)initWithInvoice:(PPHInvoice*)invoice;

/*! Retrieve the total using a custom composition
 * @param composition Which parts should be included in the total
 */
-(NSDecimalNumber*)totalWithParts:(PPHInvoiceTotalParts)composition;
@end
