//
//  InvoiceManager.h
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/16/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PayPalHereSDK/PPHInvoice.h>
@interface InvoicesManager : NSObject

+(NSMutableArray *) getCurrentTransactions;
+(void) removeTransaction: (PPHInvoice *)invoice;
+(void) addTransaction: (PPHInvoice *) invoice;
@end
