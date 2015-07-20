//
//  PPHReceiptTransactionStatus.h
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 3/27/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

typedef NS_ENUM(UInt8, PPHReceiptTransactionStatus) {
    ePPHReceiptTransactionStatusPaid,
    ePPHReceiptTransactionStatusPaymentDeclined,
    ePPHReceiptTransactionStatusPaymentCancelled,
    ePPHReceiptTransactionStatusRefunded,
    ePPHReceiptTransactionStatusRefundDeclined,
    ePPHReceiptTransactionStatusRefundCancelled
};