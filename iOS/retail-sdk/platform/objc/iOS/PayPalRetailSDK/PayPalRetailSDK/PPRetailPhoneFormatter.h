//
//  PPRetailPhoneFormatter.h
//  Pods
//
//  Created by Marasinghe,Chathura on 8/18/17.
//
//

#import <Foundation/Foundation.h>

@interface PPRetailPhoneFormatter : NSNumberFormatter

+ (instancetype)phoneFormatterWithCountryCode:(NSString *)countryCode;
+ (NSString *)countryNumberForPhone:(NSString *)phone;
+ (NSString *)countryNumberForCountryCode:(NSString *)countryCode;
- (NSString *)formatPhone:(NSString *)phone;
- (NSString *)removeFormattingFromPhone:(NSString *)phone;
- (NSString *)formatForPhoneWithCountryCode:(NSString *)phone;
- (NSString *)formatForPhone:(NSString *)phone;

@end
