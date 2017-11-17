//
//  UIButton+PPStyle.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "UIButton+PPStyle.h"
#import "PayPalRetailSDKStyles.h"

@implementation UIButton (PPStyle)

+ (UIButton *)PPButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 2;
    button.titleLabel.textColor = [PayPalRetailSDKStyles viewBackgroundColor];
    button.titleLabel.font = [PayPalRetailSDKStyles font];
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    return button;
}

- (UIButton *)PPButtonPrimary {
    [self setBackgroundColor:[PayPalRetailSDKStyles primaryButtonColor]];
    [self setBackgroundImage:[self imageWithColor:[PayPalRetailSDKStyles primaryButtonColor]] forState:UIControlStateHighlighted];
    return self;
}

- (UIButton *)PPButtonSecondary {
    [self setBackgroundColor:[PayPalRetailSDKStyles secondaryButtonColor]];
    [self setBackgroundImage:[self imageWithColor:[PayPalRetailSDKStyles secondaryButtonColor]] forState:UIControlStateHighlighted];
    return self;
}

- (UIImage *)imageWithColor:(UIColor *)color {
    CGRect rect = CGRectMake(0.0f, 0.0f, 1.0f, 1.0f);
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor(context, [color CGColor]);
    CGContextFillRect(context, rect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}
@end
