//
//  CurrentTransactionManager.m
//  SDKSampleAppWithSource
//
//  Created by Samuel Jerome on 6/16/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#define currentTransactionKey @"currentTransactionsKey"

#import "CurrentTransactionsManager.h"

@implementation CurrentTransactionsManager
static NSMutableArray *transactions;

+(NSMutableArray *) getCurrentTransactions {
    if (!transactions) {
        // if on disk, get from disk
        // else, init a new one
        
        transactions = [[NSMutableArray alloc] init];
    }
    
    return transactions;
}
+(void) removeTransaction: (PPHInvoice *)invoice {
    transactions = [CurrentTransactionsManager getCurrentTransactions];
    [transactions removeObject:invoice];
    
    
// store on disk
//    [[NSUserDefaults standardUserDefaults] setObject:transactions forKey:currentTransactionKey];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}

+(void) addTransaction: (PPHInvoice *) invoice {
    transactions = [CurrentTransactionsManager getCurrentTransactions];
    
    if ([transactions containsObject:invoice]) {
        return;
    }
    
    [transactions addObject:invoice];
    
    // store locally on disk
//    NSData *customObjectData = [NSKeyedArchiver archivedDataWithRootObject:transactions];
//    [[NSUserDefaults standardUserDefaults] setObject:customObjectData forKey:currentTransactionKey];
//    [[NSUserDefaults standardUserDefaults] synchronize];
}


@end
