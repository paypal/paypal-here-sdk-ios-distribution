//
//  PPAlertView.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/3/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class PPAlertView;

typedef void (^PPAlertViewSelectionBlock)(PPAlertView *alertView, NSInteger selectedIndex);

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPAlertView : UIView

+ (PPAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                  cancelButtonTitle:(NSString *)cancelButtonTitle
                  otherButtonTitles:(NSArray *)otherButtonTitles
                       showActivity:(BOOL)showActivity
                   selectionHandler:(PPAlertViewSelectionBlock)selectionHandler;

@property (nonatomic) NSInteger cancelButtonIndex;
@property (nonatomic) UIInterfaceOrientation desiredOrientation;

- (void)dismissAnimated:(BOOL)animated;

- (void)setTitle:(NSString *)title;
- (void)setMessage:(NSString *)message;
- (void)setTitle:(NSString *)title message:(NSString *)message;
- (void)rotateToOrientation:(UIInterfaceOrientation)toOrientation;
@end
