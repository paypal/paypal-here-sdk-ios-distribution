//
//  PlatformView+PPAutoLayout.h
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
#import <UIKit/UIKit.h>
#define PLATFORMVIEW UIView
#define PLATFORMINSETS UIEdgeInsets
#define PLATFORMINSETZERO UIEdgeInsetsZero
#else
#import <Cocoa/Cocoa.h>
#define PLATFORMVIEW NSView
#define PLATFORMINSETS NSEdgeInsets
#define PLATFORMINSETZERO NSEdgeInsetsZero
#endif

typedef NS_OPTIONS(unsigned long, PPViewEdge){
    PPViewEdgeTop = 1 << 0,
    PPViewEdgeRight = 1 << 1,
    PPViewEdgeBottom = 1 << 2,
    PPViewEdgeLeft = 1 << 3,
    PPViewEdgeTopLeft = PPViewEdgeTop | PPViewEdgeLeft,
    PPViewEdgeTopRight = PPViewEdgeTop | PPViewEdgeRight,
    PPViewEdgeBottomLeft = PPViewEdgeBottom | PPViewEdgeLeft,
    PPViewEdgeBottomRight = PPViewEdgeBottom | PPViewEdgeRight,
    PPViewEdgesHorizontal = PPViewEdgeRight | PPViewEdgeLeft,
    PPViewEdgesVertical = PPViewEdgeBottom | PPViewEdgeTop,
    PPViewEdgeAll = PPViewEdgeTop | PPViewEdgeRight | PPViewEdgeBottom | PPViewEdgeLeft
};

@interface PLATFORMVIEW (PPAutoLayout)
- (void)addSimpleVisualConstraint:(NSString *)visualConstraint withBindings:(NSDictionary *)bindings;
- (NSLayoutConstraint *)pinAttribute:(NSLayoutAttribute)attribute toSameOfView:(PLATFORMVIEW *)view;
- (NSArray *)centerInSuperview;
- (NSLayoutConstraint *)centerInSuperviewOnAxis:(NSLayoutAttribute)axis;
- (NSArray *)stretchInSuperview;
- (NSArray *)pinInSuperviewToEdges:(PPViewEdge)edges withInset:(CGFloat)inset;
- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(PLATFORMVIEW *)view inset:(CGFloat)inset;
- (NSArray *)stretchInSuperviewWithInset:(PLATFORMINSETS)insets;
- (NSLayoutConstraint *)constrainToWidth:(CGFloat)width;
- (NSLayoutConstraint *)constrainToHeight:(CGFloat)height;

@property (nonatomic) CGFloat frameWidth;
@property (nonatomic) CGFloat frameHeight;
@property (nonatomic) CGFloat frameTop;
@property (nonatomic) CGFloat frameLeft;
@property (nonatomic) CGFloat frameMidY;
@end
