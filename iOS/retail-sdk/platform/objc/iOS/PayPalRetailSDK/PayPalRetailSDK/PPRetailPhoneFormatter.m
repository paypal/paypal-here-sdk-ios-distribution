//
//  PPRetailPhoneFormatter.m
//  Pods
//
//  Created by Marasinghe,Chathura on 8/18/17.
//
//

#import "PPRetailPhoneFormatter.h"
#import "PPRetailUtils.h"
#import "PPRetailCoreServices.h"

#define PPR_PHONE_FORMATTER_FORMATS_KEY                @"Formats"
#define PPR_PHONE_FORMATTER_CONDITIONS_KEY             @"Conditions"
#define PPR_PHONE_FORMATTER_COUNTRY_CODE_KEY           @"CountryCode"
#define PPR_PHONE_FORMATTER_LEADING_ZERO_SUPPORT_KEY   @"LeadingZeroSupport"
#define PPR_PHONE_FORMATTER_PLIST                      @"RetailCountryPhoneFormats"

#define PPR_PHONE_FORMATTER_DEFAULT_FORMAT             @"DEFAULT"

@interface PPRetailPhoneFormatter ()

@property (nonatomic, strong) NSDictionary *currentCountryDictionary;
@property (nonatomic, copy) NSString *currentFormat;

@end

@implementation PPRetailPhoneFormatter

#pragma mark -
#pragma mark initialization

static NSDictionary *codeDict;

+ (void)initialize {
    codeDict = [PPRetailCoreServices countryPhoneCodesList];
}

+ (instancetype)phoneFormatterWithCountryCode:(NSString *)countryCode {
    PPRetailPhoneFormatter *phoneFormatter = [[PPRetailPhoneFormatter alloc] init];
    
    if (!countryCode) {
        countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    }
    [phoneFormatter setCountryCode:countryCode];
    return phoneFormatter;
}

#pragma mark -
#pragma mark visibles

- (NSString *)formatPhone:(NSString *)phone {
    return [self stringForObjectValue:phone];
}

- (NSString *)removeFormattingFromPhone:(NSString *)phone {
    NSString *cleanString;
    NSString *error;
    if ([self getObjectValue:&cleanString forString:phone errorDescription:&error]) {
        
    }
    return cleanString;
}

#pragma mark -
#pragma mark formats

- (NSString *)formatForPhone:(NSString *)phone fromDictionary:(NSDictionary *)countryDictionary {
    
    NSString *countryPhoneCode = countryDictionary[PPR_PHONE_FORMATTER_COUNTRY_CODE_KEY];
    NSDictionary *formats = countryDictionary[PPR_PHONE_FORMATTER_FORMATS_KEY];
    NSMutableString *returnFormat = [NSMutableString stringWithString:formats[PPR_PHONE_FORMATTER_DEFAULT_FORMAT]];
    NSDictionary *conditions = countryDictionary[PPR_PHONE_FORMATTER_CONDITIONS_KEY];
    BOOL supportsLeadingZero = [countryDictionary[PPR_PHONE_FORMATTER_LEADING_ZERO_SUPPORT_KEY] boolValue];
    
    NSMutableString *currentFormat = [NSMutableString string];
    BOOL hasCountryCode = [phone hasPrefix:countryPhoneCode];
    if (hasCountryCode) {
        [currentFormat appendString:@"+"];
        for (int i = 0; i < countryPhoneCode.length; i ++) {
            [currentFormat appendString:@"#"];
        }
        [currentFormat appendString:@" "];
    }
    
    if (conditions) {
        for (NSString *key in conditions) {
            NSMutableString *properPhone = [NSMutableString stringWithString:phone];
            if (hasCountryCode) {
                [properPhone replaceCharactersInRange:NSMakeRange(0, countryPhoneCode.length)
                                           withString:@""];
            }
            if (supportsLeadingZero && [phone hasPrefix:@"0"]) {
                [properPhone replaceCharactersInRange:NSMakeRange(0, 1)
                                           withString:@""];
            }
            if ([properPhone hasPrefix:key]) {
                NSString *testFormat = formats[conditions[key]];
                if (testFormat) {
                    returnFormat = [NSMutableString stringWithString:testFormat];
                    if (supportsLeadingZero && [phone hasPrefix:@"0"]) {
                        [returnFormat insertString:@"#" atIndex:0];
                    }
                    break;
                }
            }
        }
    }
    if (phone.length >1 && !hasCountryCode && supportsLeadingZero && ![phone hasPrefix:@"0"]) {
        [returnFormat insertString:@"0" atIndex:0];
    }
    
    return [currentFormat stringByAppendingString:returnFormat];
}

- (NSString *)formatForPhoneWithCountryCode:(NSString *)phone {
    NSDictionary *computedDictionary = self.currentCountryDictionary;
    for (NSString *key in codeDict) {
        if ([phone hasPrefix:codeDict[key][PPR_PHONE_FORMATTER_COUNTRY_CODE_KEY]]) {
            computedDictionary = codeDict[key];
            break;
        }
    }
    return [self formatForPhone:phone fromDictionary:computedDictionary];
}

+ (NSString *)countryNumberForCountryCode:(NSString *)countryCode {
    return [codeDict objectForKey:countryCode] ? codeDict[countryCode][PPR_PHONE_FORMATTER_COUNTRY_CODE_KEY] : @"";
}

+ (NSString *)countryNumberForPhone:(NSString *)phone {
    
    NSString *cleanedPhone = [[self new] removeFormattingFromPhone:phone];
    
    // Loop through all the country codes we support, and try to find one that could be the country code of this phone number.
    // A given country code could be the code of this number iff:
    //   1. This number starts with the country code.
    //   2. Removing the country code from this number wouldn't make the number too short to be a real phone number (under 10 characters).
    NSString *countryCode;
    for (NSString *key in codeDict) {
        NSString *code = codeDict[key][PPR_PHONE_FORMATTER_COUNTRY_CODE_KEY];
        if ([cleanedPhone hasPrefix:code] && cleanedPhone.length - code.length >= 10) {
            countryCode = code;
            break;
        }
    }
    
    if (!countryCode) {
        NSString *locale = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
        countryCode = codeDict[locale][PPR_PHONE_FORMATTER_COUNTRY_CODE_KEY];
    }
    
    //If we still haven't found a match default to US
    return countryCode ?: @"1";
}

#pragma mark -
#pragma mark overrides

- (void)setCountryCode:(NSString *)countryCode {
    NSDictionary *currentDict = codeDict[countryCode];
    if (currentDict == nil) {
        currentDict = codeDict[@"US"];
    }
    self.currentCountryDictionary = currentDict;
}

- (NSString *)formatForPhone:(NSString *)phone {
    [self stringForObjectValue:phone];
    return self.currentFormat;
}

- (NSString *)stringForObjectValue:(id)obj {
    NSString *cleanString = nil;
    NSString *error;
    
    BOOL shouldAppendPlus = [obj hasPrefix:@"+"];
    NSMutableString *currentFormat;
    
    if ([self getObjectValue:&cleanString forString:obj errorDescription:&error]) {
        currentFormat= [NSMutableString string];
        //get country code
        if (shouldAppendPlus){
            [currentFormat appendString:[self formatForPhoneWithCountryCode:cleanString]];
            // If the '+' isn't added, add one along with the correct number of #.
            if (![currentFormat hasPrefix:@"+"]) {
                [currentFormat insertString:@"+" atIndex:0];
                for (int i = 0; i < cleanString.length; i++) {
                    [currentFormat insertString:@"#" atIndex:1];
                }
            }
        } else {
            [currentFormat appendString:[self formatForPhone:cleanString
                                              fromDictionary:self.currentCountryDictionary]];
        }
        int currentStringIndex = 0;
        NSMutableString *temp = [NSMutableString string];
        
        if (shouldAppendPlus && ![currentFormat hasPrefix:@"+"]) {
            [temp appendString:@"+"];
        }
        
        for(int currentFormatIndex = 0;
            temp != nil && currentStringIndex < [cleanString length] && currentFormatIndex < [currentFormat length];
            currentFormatIndex++) {
            
            char c = [currentFormat characterAtIndex:currentFormatIndex];
            char next = [cleanString characterAtIndex:currentStringIndex];
            
            switch(c) {
                case '*':
                    [temp appendString:[cleanString substringWithRange:NSMakeRange(currentStringIndex, cleanString.length - currentStringIndex)]];
                    currentStringIndex = (int)[cleanString length];
                    break;
                case '#':
                    [temp appendFormat:@"%c", next];
                    currentStringIndex++;
                    break;
                case '+':
                    [temp appendString:@"+"];
                    break;
                case '0':
                    [temp appendString:@"0"];
                    break;
                default:
                    [temp appendFormat:@"%c", c];
                    if(next == c) {
                        currentStringIndex++;
                    }
                    
                    break;
            }
        }
        cleanString = temp;
    }
    
    self.currentFormat = currentFormat;
    return cleanString;
}

- (BOOL)getObjectValue:(out id *)obj forString:(NSString *)string errorDescription:(out NSString **)error {
    BOOL returnValue;
    if (obj) {
        returnValue = YES;
        
        NSMutableString *strippedString = [NSMutableString string];
        NSScanner *scanner = [NSScanner scannerWithString:string];
        NSCharacterSet *numbers = [NSCharacterSet
                                   characterSetWithCharactersInString:@"0123456789*"];
        while ([scanner isAtEnd] == NO) {
            NSString *buffer;
            if ([scanner scanCharactersFromSet:numbers intoString:&buffer]) {
                [strippedString appendString:buffer];
            } else {
                [scanner setScanLocation:([scanner scanLocation] + 1)];
            }
        }
        *obj = [NSString stringWithString:strippedString];
    } else {
        if (error) {
            *error = @"Couldn’t convert to clean number";
        }
        returnValue = NO;
    }
    return returnValue;
}

@end
