//
//  UIButton+CustomButton.m
//  PPHSDKSampleApp
//
//  Created by Deol, Sukhpreet(AWF) on 9/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import "UIButton+CustomButton.h"

@implementation CustomButton
+(void)customizeButton:(UIButton *)button{
    button.layer.borderWidth = 1;
    button.layer.borderColor = [self colorFromHexString:@"0068AE"].CGColor;
    button.layer.cornerRadius = button.frame.size.height/2;
}

+(void)buttonWasSelected:(UIButton *)button{
    button.layer.borderWidth = 0;
    button.backgroundColor = UIColor.clearColor;
    button.layer.cornerRadius = 0;
    button.imageEdgeInsets = UIEdgeInsetsMake(0, button.frame.size.width - 30, 0, 0);
    [button setTitle:@"" forState:UIControlStateDisabled];
    [button setImage:[UIImage imageNamed:@"Check"] forState:UIControlStateDisabled];
}

+(UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}
@end
