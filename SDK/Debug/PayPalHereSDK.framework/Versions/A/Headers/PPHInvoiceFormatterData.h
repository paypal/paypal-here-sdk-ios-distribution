//
//  PPHInvoiceFormatterData.h
//  PayPalHereSDK
//
//  Created by Colin Fyffe on 5/6/14.
//  Copyright 2014 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHTransactionManager.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
typedef NS_ENUM(UInt8, PPHPrinterFormat) {
    ePPHPrinterFormatText,
    ePPHPrinterFormatHtml,
};

typedef NS_ENUM(UInt8, PPHInvoiceReceiptType) {
    ePPHInvoiceReceiptCustomer,
    ePPHInvoiceReceiptMerchant,
    ePPHInvoiceReceiptGift
};

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPHInvoiceFormatterData : NSObject

@property (nonatomic, assign) PPHPrinterFormat format;
@property (nonatomic, assign) NSUInteger lineWidth;

@property (nonatomic, assign) PPHInvoiceReceiptType receiptType;
@property (nonatomic, assign) PPHTransactionStatus txnStatus;
@property (nonatomic, strong) NSString *returnPolicy;
@property (nonatomic, strong) NSString *footerText;

-(id)initWithFormat:(PPHPrinterFormat)format
          lineWidth:(NSUInteger)lineWidth
        receiptType:(PPHInvoiceReceiptType)receiptType
          txnStatus:(PPHTransactionStatus)txnStatus
       returnPolicy:(NSString *)returnPolicy
         footerText:(NSString *)footerText;

@end
