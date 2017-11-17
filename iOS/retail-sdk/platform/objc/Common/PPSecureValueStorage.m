//
//  PPSecureValueStorage.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/27/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPSecureValueStorage.h"
#import "PayPalRetailSDK+Private.h"
#import <CommonCrypto/CommonDigest.h>

static NSString *sServiceName = @"com.paypal.retail.sdk";
static NSLock *sKeychainLock = nil;
static NSString *sCurrentUserID = nil;

@implementation PPSecureValueStorage
+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sKeychainLock = [[NSLock alloc] init];
    });
}

+ (NSLock *)getKeychainLock
{
    NSAssert(sKeychainLock != nil, @"Keychain lock must exist here...");
    return sKeychainLock;
}

+ (NSString *) stringForSecureKey:(NSString *) key
{
    NSLock * pKeyChainNSLock = [self getKeychainLock];
    @synchronized(pKeyChainNSLock) {
        NSString* str = nil;
        NSData* keyData = [PPSecureValueStorage searchKeychainMatching:[self hashForKey:key]];

        if ( keyData != nil )
        {
            str = [[NSString alloc] initWithData:keyData encoding:NSUTF8StringEncoding];
        }

        return str;
    }
}

+ (BOOL) setString:(NSString *) string forSecureKey:(NSString *) key
{
    NSLock * pKeyChainNSLock = [self getKeychainLock];
    @synchronized(pKeyChainNSLock) {
        NSData *keyData = [string dataUsingEncoding:NSUTF8StringEncoding];

        BOOL retval = [PPSecureValueStorage updateOrCreateKeychainValue:keyData forIdentifier:[self hashForKey:key]];

        return retval;
    }
}

+ (void) deleteValueForSecureKey:(NSString *) key
{
    NSLock * pKeyChainNSLock = [self getKeychainLock];
    @synchronized(pKeyChainNSLock) {
        NSMutableDictionary *searchDictionary = [PPSecureValueStorage newSearchDictionary:[self hashForKey:key]];
        SecItemDelete((__bridge CFDictionaryRef)searchDictionary);
    }
}


+ (BOOL) createKeychainValue:(NSData *) data forIdentifier:(NSString *) identifier
{
    NSMutableDictionary *dictionary = [PPSecureValueStorage newSearchDictionary:identifier];
    [dictionary setObject:data forKey:(__bridge id)kSecValueData];
    [dictionary setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);

    if (status == errSecSuccess)
    {
        return YES;
    }

    return NO;
}

+(NSMutableDictionary *)newSearchDictionary:(NSString *)identifier
{
    NSMutableDictionary *searchDictionary = [[NSMutableDictionary alloc] init];

    [searchDictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];

    NSData *encodedIdentifier = [identifier dataUsingEncoding:NSUTF8StringEncoding];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrGeneric];
    [searchDictionary setObject:encodedIdentifier forKey:(__bridge id)kSecAttrAccount];
    [searchDictionary setObject:sServiceName forKey:(__bridge id)kSecAttrService];

    return searchDictionary;
}

// Searches the keychain for the given key. Returns nil if not found.
+ (NSData *) searchKeychainMatching:(NSString *) identifier
{
    NSMutableDictionary *searchDictionary = [PPSecureValueStorage newSearchDictionary:identifier];

    // Add search attributes
    [searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];

    // Add search return types
    [searchDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];

    CFTypeRef resultData = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary,
                                          (CFTypeRef *)&resultData);

    if ( status != noErr )
    {
        SDK_DEBUG(@"native", @"Could not find %@ in keychain (result code = %d)", identifier, (int)status);
        return nil;
    }

    if (resultData == nil)
    {
        return nil;
    }

    NSData *data = [NSData dataWithData:(__bridge NSData *) resultData];
    CFRelease(resultData);

    return data;
}

// Updates an existing entry, will fail if entry does not exist
+ (BOOL) updateKeychainValue:(NSData *) data forIdentifier:(NSString *) identifier
{
    NSMutableDictionary *searchDictionary = [PPSecureValueStorage newSearchDictionary:identifier];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    [updateDictionary setObject:data forKey:(__bridge id)kSecValueData];
    [updateDictionary setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary,
                                    (__bridge CFDictionaryRef)updateDictionary);

    if (status == errSecSuccess) {
        return YES;
    }

    return NO;
}

+ (BOOL) updateOrCreateKeychainValue:(NSData *) data forIdentifier:(NSString *) identifier
{
    if ([PPSecureValueStorage searchKeychainMatching:identifier] != nil)
    {
        return [PPSecureValueStorage updateKeychainValue:data forIdentifier:identifier];
    }
    else
    {
        return [PPSecureValueStorage createKeychainValue:data forIdentifier:identifier];
    }
}

+(NSString *)hashForKey:(NSString *)key {
    const char *cstr = [key UTF8String];
    unsigned char result[16];
    CC_MD5(cstr, (unsigned int) strlen(cstr), result);
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
    ];
}

@end
