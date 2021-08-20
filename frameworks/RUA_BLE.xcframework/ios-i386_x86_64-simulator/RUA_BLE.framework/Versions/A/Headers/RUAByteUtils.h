//
//  ByteUtils.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 10/21/13.
//  Copyright (c) 2013 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>

static char base64EncodingTable[64] = {
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
    'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
    'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
    'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
};

@interface RUAByteUtils : NSObject

/**
 Converts Hexadecimal string to NSData
 @param Hexadecimal string
 @return NSData representation of the string
 */
+ (NSData *)convertHexString:(NSString *)hexString;

/**
 Converts NSData string to Hexadecimal string
 @param NSData representation of the string
 @return Hexadecimal string
 */
+ (NSString *)convertNSDatatoHexadecimal:(NSData *)data;

/**
 Converts ByteArray string to Hexadecimal string
 @param byte array
 @param length
 @return Hexadecimal string
 */
+ (NSString *)convertByteArraytoHexadecimal:(Byte *)data withLength:(int)length;

/**
 Converts NSData to ASCII string
 @param NSData data
 @return ASCII string
 */
+ (NSString *)convertNSDATAtoASCIIString:(NSData *)data;

/**
 Converts Hex String to ASCII string
 @param Hexadecimal string
 @return ASCII String
 */
+ (NSString *)convertHexStringtoASCIIString:(NSString *)hexString;

/**
 Converts ASCII string to Hex String
 @param ASCII string
 @return Hexadecimal String
 */
+ (NSString *) convertASCIIStringToHexString:(NSString *)str;

/**
 Converts Data to Base 64 encoded string
 @param data
 @param length
 @return Base 64 encoded string
 */
+ (NSString *) base64EncodedStringFromData:(NSData *)data;

/**
 Converts Hex String to Base 64 encoded string
 @param data
 @param length
 @return Base 64 encoded string
 */
+ (NSString *) base64EncodedStringFromHexadecimalString: (NSString *) hexString;

+ (int) NSDataToInt:(NSData *)data;

@end
