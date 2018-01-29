//
//  RUAPublicKey.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/18/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RUAPublicKey : NSObject

/**
 * RID - Registered Application Provider Identifier
 * */
@property NSString *rid;
/**
 * Certification Authority Public Key Index
 * */
@property NSString *caPublicKeyIndex;
/**
 * Public Key
 * */
@property NSString *publicKey;
/**
 * Exponent of Public Key
 * */
@property NSString *exponentOfPublicKey;
/**
 * Checksum of Public key
 * */
@property NSString *checksum;

- (id)          initWithRID:(NSString *)rid
       withCAPublicKeyIndex:(NSString *)CAPublicKeyIndex
              withPublicKey:(NSString *)PublicKey
    withExponentOfPublicKey:(NSString *)ExponentOfPublicKey;

- (id)          initWithRID:(NSString *)rid
       withCAPublicKeyIndex:(NSString *)CAPublicKeyIndex
              withPublicKey:(NSString *)PublicKey
    withExponentOfPublicKey:(NSString *)ExponentOfPublicKey
               withChecksum:(NSString *)checksum;

- (NSString *)getFormattedString;

@end
