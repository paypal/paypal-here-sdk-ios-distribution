//
//  NSString+Common.m
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 3/20/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "NSString+Common.h"

@implementation NSString (Common)

-(NSString *)currencyInputFormatting {
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDecimalNumber * number = [NSDecimalNumber alloc];
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle =  NSNumberFormatterCurrencyAccountingStyle;
    formatter.currencySymbol = [userDefaults stringForKey:@"CURRENCY_SYMBOL"];
    formatter.maximumFractionDigits = 2;
    formatter.minimumFractionDigits = 2;
    NSString *amountWithPrefix = self;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^0-9]"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    amountWithPrefix = [regex stringByReplacingMatchesInString:amountWithPrefix options:0 range:NSMakeRange(0,[self length]) withTemplate:@""];
    
    number = [NSDecimalNumber decimalNumberWithDecimal:[[NSDecimalNumber numberWithDouble:[amountWithPrefix doubleValue]/100] decimalValue]];
    if([number.stringValue isEqualToString:@"0"]) {
        return @"";
    }
    return [formatter stringFromNumber:number];
}

@end
