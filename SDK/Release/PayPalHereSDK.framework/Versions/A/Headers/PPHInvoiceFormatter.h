//
//  PPHInvoiceFormatter.h
//  PayPalHereSDK
//
//  Created by Metral, Max on 7/28/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PPHInvoice;
@class UIImage;

typedef NS_ENUM(UInt8, PPHInvoiceReceiptType) {
    ePPHInvoiceReceiptCustomer,
    ePPHInvoiceReceiptMerchant,
    ePPHInvoiceReceiptGift
};

@interface PPHInvoiceFormatter : NSObject

/**
 * Initialize the invoice formatter with default properties, namely character based with a 40 column width
 */
-(id) init;

/**
 * Format the invoice according to the formatter settings and return a string suitable for printing in
 * a fixed width font
 */
-(NSString*) formattedStringForInvoice: (PPHInvoice*) invoice;


/**
 * Format the invoice according to the formatter settings and return an HTML string suitable for printing.
 * If you want to customize the look and feel, the output will contain "targetable" CSS classes and structure
 * to allow a decent amount of customization, and will be XHTML for easy modification.
 */
-(NSString*) htmlStringForInvoice: (PPHInvoice*) invoice;

/**
 * Format the invoice according to the formatter settings and return an image with the specified width
 * and height depending on the number of items on the invoice. This is essentially using the htmlStringForInvoice
 * method and rendering it down to an image for you.
 */
-(UIImage*) formattedImageForInvoice: (PPHInvoice*) invoice withWidth: (NSInteger) widthInPixels;

/**
 * The number of columns used in the receipt (since we use fixed width fonts in all cases)
 */
@property (nonatomic,assign) NSInteger columnWidth;

/**
 * The type of receipt that should be produced by this formatter. You can change this between calls.
 */
@property (nonatomic,assign) PPHInvoiceReceiptType receiptType;
@end
