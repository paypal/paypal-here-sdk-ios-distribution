//
//  PPSCryptoUtils.h
//  Here and There
//
//  Created by Metral, Max on 2/25/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPSCryptoUtils : NSObject
+ (NSString *)AES256Decrypt: (NSString*) inputPacket withPassword:(NSString *)password;
+ (NSData *)AESKeyForPassword:(NSString *)password salt:(NSData *)salt;
+ (NSData *)dataFromBase64String:(NSString *)aString;
+ (NSString *)base64EncodedStringForData: (NSData*)data;
@end
