//
//  PayPalRetailSDKStyles.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/3/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PayPalRetailSDKStyles.h"

/**
 * This is not settable because layouts would change, and we haven't made layouts
 * configurable yet, so... yeah.
 */
#define kDefaultFontSize 15

@implementation PayPalRetailSDKStyles
+(UIColor *)viewBackgroundColor {
    return [UIColor whiteColor];
}

+(UIColor *)screenMaskColor {
    return [UIColor colorWithWhite:.1 alpha:0.5];
}

+(UIFont *)font {
    return [UIFont fontWithName:@"HelveticaNeue" size:kDefaultFontSize];
}

+(UIFont *)smallFont {
    return [[self font] fontWithSize:14];
}

+(UIFont *)largeFont {
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:57];
}

+(UIFont*)fontWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue" size:size];
}

+(UIFont*)lightFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Light" size:size];
}

+(UIFont*)mediumFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Medium" size:size];
}

+(UIFont*)boldFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:@"HelveticaNeue-Bold" size:size];
}

+(UIColor *)primaryButtonColor {
    return UIColorFromRGB(0x009cde);
}

+(UIColor *)secondaryButtonColor {
    return UIColorFromRGB(0x6e7c8a);
}

+(UIColor *)primaryTextColor {
    return UIColorFromRGB(0x3d5266);
}

+(UIColor *)secondaryTextColor {
    return UIColorFromRGB(0x97aabd);
}

+(UIColor *)primaryNavBarColor {
    return UIColorFromRGB(0x009cde);
}


@end
