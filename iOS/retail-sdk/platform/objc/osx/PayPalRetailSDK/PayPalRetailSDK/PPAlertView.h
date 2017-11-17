
//
//  PPAlertView.h
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/4/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class PPAlertView;

typedef void (^PPAlertViewSelectionBlock)(PPAlertView *alertView, NSInteger selectedIndex);

@interface PPAlertView : NSWindow

+ (PPAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                  cancelButtonTitle:(NSString *)cancelButtonTitle
                  otherButtonTitles:(NSArray *)otherButtonTitles
                       showActivity:(BOOL)showActivity
                   selectionHandler:(PPAlertViewSelectionBlock)selectionHandler;

@property (nonatomic) NSInteger cancelButtonIndex;
@property (nonatomic, copy) PPAlertViewSelectionBlock selectionHandler;

- (void)dismissAnimated:(BOOL)animated;

- (void)setTitle:(NSString *)title;
- (void)setMessage:(NSString *)message;
- (void)setTitle:(NSString *)title message:(NSString *)message;
@end
