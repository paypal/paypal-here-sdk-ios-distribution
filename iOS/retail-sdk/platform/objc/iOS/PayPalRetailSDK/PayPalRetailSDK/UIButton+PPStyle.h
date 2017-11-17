//
//  UIButton+PPStyle.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIButton (PPStyle)
+ (UIButton *)PPButton;
- (UIButton *)PPButtonPrimary;
- (UIButton *)PPButtonSecondary;
- (UIImage *)imageWithColor:(UIColor *)color;
@end
