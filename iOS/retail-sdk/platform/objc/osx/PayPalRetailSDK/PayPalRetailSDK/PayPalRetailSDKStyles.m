//
//  PayPalRetailSDKStyles.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/4/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PayPalRetailSDKStyles.h"

#define NSColorFromRGB(rgbValue) [NSColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

/**
 * This is not settable because layouts would change, and we haven't made layouts
 * configurable yet, so... yeah.
 */
#define kDefaultFontSize 15

@implementation PayPalRetailSDKStyles
+(NSColor *)viewBackgroundColor {
    return [NSColor whiteColor];
}

+(NSColor *)screenMaskColor {
    return [NSColor colorWithWhite:.1 alpha:0.5];
}

+(NSFont *)font {
    return [NSFont fontWithName:@"HelveticaNeue" size:kDefaultFontSize];
}

+(NSColor *)primaryButtonColor {
    return NSColorFromRGB(0x009cde);
}

+(NSColor *)secondaryButtonColor {
    return NSColorFromRGB(0x6e7c8a);
}

+(NSColor *)primaryTextColor {
    return NSColorFromRGB(0x3d5266);
}
@end
