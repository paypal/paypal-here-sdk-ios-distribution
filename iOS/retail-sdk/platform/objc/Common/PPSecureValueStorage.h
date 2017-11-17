//
//  PPSecureValueStorage.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/27/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPSecureValueStorage : NSObject
+ (NSString *) stringForSecureKey:(NSString *) key;
+ (BOOL) setString:(NSString *) string forSecureKey:(NSString *) key;
+ (void) deleteValueForSecureKey:(NSString *) key;
+ (NSString *) hashForKey:(NSString*)key;
@end
