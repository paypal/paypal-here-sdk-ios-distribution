//
//  PayPalRetailSDKStyles.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/3/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface PayPalRetailSDKStyles : NSObject

+(UIColor*)viewBackgroundColor;
+(UIColor*)screenMaskColor;

+(UIColor*)primaryButtonColor;
+(UIColor*)secondaryButtonColor;

+(UIColor*)primaryTextColor;
+(UIColor *)secondaryTextColor;

+(UIColor *)primaryNavBarColor;

+(UIFont*)font;
+(UIFont*)smallFont;
+(UIFont*)largeFont;

+(UIFont*)fontWithSize:(CGFloat)size;
+(UIFont*)lightFontWithSize:(CGFloat)size;
+(UIFont*)mediumFontWithSize:(CGFloat)size;
+(UIFont*)boldFontWithSize:(CGFloat)size;
@end
