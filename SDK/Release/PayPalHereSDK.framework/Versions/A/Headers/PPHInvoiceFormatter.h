//
//  PPHInvoiceFormatter.h
//  PayPalHereSDK
//
//  Created by Metral, Max on 7/28/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHInvoiceFormatterData.h"

@class PPHInvoice;
@class UIImage;

/*!
 * PPHInvoiceFormatter is capable of rendering the details of invoices for receipt purposes. Online receipts
 * are typically hosted by PayPal, but this class is mainly useful for producing printable receipts.
 */
@interface PPHInvoiceFormatter : NSObject

/**
 * Format the invoice according to the formatter settings with the given properties and return a string suitable for printing in
 * a fixed width font
 * @param invoice The invoice receipt to be printed
 */
-(NSString*) formattedStringForInvoice: (PPHInvoice*) invoice withFormatData:(PPHInvoiceFormatterData*) data;

/**
 * Format the invoice according to the formatter settings and return a string suitable for printing in
 * a fixed width font
 * @param invoice The invoice receipt to be printed
 */
-(NSString*) formattedStringForInvoice: (PPHInvoice*) invoice;


/**
 * Format the invoice according to the formatter settings and return an image with the specified width
 * and height depending on the number of items on the invoice. This is essentially using the htmlStringForInvoice
 * method and rendering it down to an image for you.
 * @param invoice The invoice receipt to be printed
 * @param widthInPixels The width of the returned image - height will be determined based on this
 */
-(UIImage*) formattedImageForInvoice: (PPHInvoice*) invoice withWidth: (NSInteger) widthInPixels;

@end
