//
//  UIButton+CustomButton.h
//  PPHSDKSampleApp
//
//  Created by Deol, Sukhpreet(AWF) on 9/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomButton: UIView
+(void)customizeButton:(UIButton *) button;
+(void)buttonWasSelected:(UIButton *) button;
+(UIColor *)colorFromHexString:(NSString *)hexString;
@end
