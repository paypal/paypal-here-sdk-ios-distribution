//
//  CurrentTransactionManager.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/16/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#define currentTransactionKey @"currentTransactionsKey"

#import "InvoicesManager.h"

@implementation InvoicesManager
static NSMutableArray *transactions;

+(NSMutableArray *) getCurrentTransactions {
    if (!transactions) {
        transactions = [[NSMutableArray alloc] init];
    }
    
    return transactions;
}
+(void) removeTransaction: (PPHInvoice *)invoice {
    transactions = [InvoicesManager getCurrentTransactions];
    [transactions removeObject:invoice];
}

+(void) addTransaction: (PPHInvoice *) invoice {
    transactions = [InvoicesManager getCurrentTransactions];
    
    if ([transactions containsObject:invoice]) {
        return;
    }
    
    [transactions addObject:invoice];
}


@end
