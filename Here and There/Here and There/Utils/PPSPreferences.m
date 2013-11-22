//
//  PPSPreferences.m
//  Here and There
//
//  Created by Metral, Max on 2/26/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSPreferences.h"
#import "PPSCryptoUtils.h"
#import <PayPalHereSDK/PayPalHereSDK.h>

static NSString *sServiceName = @"com.paypal.hereandthere";
static NSLock *sKeychainLock = nil;

@implementation PPSPreferences

+(PPHMerchantInfo *)merchantFromServerResponse:(NSDictionary *)JSON withMerchantId:(NSString *)merchantId
{
    PPHMerchantInfo *ppmerchant = nil;

    NSAssert([JSON objectForKey:@"merchant"], @"Your sample server should return a merchant object with information about the merchant.");
    if ([JSON objectForKey:@"merchant"]) {
        ppmerchant = [[PPHMerchantInfo alloc] init];
        // Now, you need to fill out the merchant info with the things you've gathered about the account on "your side"
        NSDictionary *yourMerchant = [JSON objectForKey:@"merchant"];
        ppmerchant.invoiceContactInfo = [[PPHInvoiceContactInfo alloc]
                                         initWithCountryCode: [yourMerchant objectForKey:@"country"]
                                         city:[yourMerchant objectForKey:@"city"]
                                         addressLineOne:[yourMerchant objectForKey:@"line1"]];
        ppmerchant.invoiceContactInfo.businessName = [yourMerchant objectForKey:@"businessName"];
        ppmerchant.invoiceContactInfo.state = [yourMerchant objectForKey:@"state"];
        ppmerchant.invoiceContactInfo.postalCode = [yourMerchant objectForKey:@"postalCode"];
        ppmerchant.currencyCode = [yourMerchant objectForKey:@"currency"];
        
        if ([JSON objectForKey:@"access_token"]) {
            NSString* key = [PPSPreferences currentTicket];
            NSString* access = [PPSCryptoUtils AES256Decrypt: [JSON objectForKey:@"access_token"] withPassword:key];
            
            PPHAccessAccount *account = [[PPHAccessAccount alloc] initWithAccessToken:access
                                                                           expires_in:[JSON objectForKey:@"expires_in"]
                                                                           refreshUrl:[JSON objectForKey:@"refresh_url"] details:JSON];
            ppmerchant.payPalAccount = account;
        }
    }
    return ppmerchant;
}

+(NSString *)currentLocationName {
    return [self stringForSecureKey:@"CurrentLocation"];
}

+(void)setCurrentLocationName:(NSString *)internalName {
    [self setString:internalName forKey:@"CurrentLocation"];
}

+(NSString *)currentTicket {
    return [self stringForSecureKey:@"CurrentTicket"];
}

+(void)setCurrentTicket:(NSString *)ticket {
    [self setString:ticket forSecureKey:@"CurrentTicket"];
}

+(NSString *)currentUsername {
    return [self stringForSecureKey:@"CurrentUsername"];
}

+(void)setCurrentUsername:(NSString *)username {
    [self setString:username forSecureKey:@"CurrentUsername"];
}

#ifdef DEBUG
+(void)setSavedPasswordInDebug:(NSString *)password {
    [self setString:password forSecureKey:@"SavedPass"];
}

+(NSString *)savedPasswordInDebug {
    return [self stringForSecureKey:@"SavedPass"];
}
#endif

#pragma mark - Internals

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

+(NSString *)stringForKey:(NSString *)key
{
	NSString* str = [[NSUserDefaults standardUserDefaults] stringForKey:key];
	return str;
}

+ (NSString *) stringForSecureKey:(NSString *) key
{
    NSLock * pKeyChainNSLock = [self getKeychainLock];
    @synchronized(pKeyChainNSLock) {
		NSString* str = nil;
		NSData* keyData = [self searchKeychainMatching:key];
		
		if ( keyData != nil )
        {
			str = [[NSString alloc] initWithData:keyData encoding:NSUTF8StringEncoding];
		}
		return str;
	}
}

+ (void) setString:(NSString *) string forKey:(NSString *) key
{
	[[NSUserDefaults standardUserDefaults] setObject:string forKey:key];
}

+ (BOOL) setString:(NSString *) string forSecureKey:(NSString *) key
{
    NSLock * pKeyChainNSLock = [self getKeychainLock];
    @synchronized(pKeyChainNSLock) {
		NSData *keyData = [string dataUsingEncoding:NSUTF8StringEncoding];
		
		BOOL retval = [self updateOrCreateKeychainValue:keyData forIdentifier:key];		
		return retval;
	}
}

+ (BOOL) createKeychainValue:(NSData *) data forIdentifier:(NSString *) identifier
{
	NSMutableDictionary *dictionary = [self newSearchDictionary:identifier];
	[dictionary setObject:data forKey:(__bridge id)kSecValueData];
	
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
	NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    
	// Add search attributes
	[searchDictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
	// Add search return types
	[searchDictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
    
	CFTypeRef resultData = NULL;
	OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)searchDictionary,
                                          (CFTypeRef *)&resultData);
    
	if ( status != noErr )
	{
        if (status != -25300) {
            NSLog(@"Could not find %@ in keychain (result code = %ld)", identifier, status);
        }
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
	NSMutableDictionary *searchDictionary = [self newSearchDictionary:identifier];
    NSMutableDictionary *updateDictionary = [[NSMutableDictionary alloc] init];
    [updateDictionary setObject:data forKey:(__bridge id)kSecValueData];
	
    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)searchDictionary,
                                    (__bridge CFDictionaryRef)updateDictionary);
	
    if (status == errSecSuccess) {
        return YES;
    }
	
    return NO;
}

+ (BOOL) updateOrCreateKeychainValue:(NSData *) data forIdentifier:(NSString *) identifier
{
	if ([self searchKeychainMatching:identifier] != nil)
    {
		return [self updateKeychainValue:data forIdentifier:identifier];
    }
	else
    {
		return [self createKeychainValue:data forIdentifier:identifier];
    }
}
@end
