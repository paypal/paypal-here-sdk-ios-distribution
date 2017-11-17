//
//  PlatformView+PPAutoLayout.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PlatformView+PPAutoLayout.h"

@implementation PLATFORMVIEW (PPAutoLayout)


- (void)addSimpleVisualConstraint:(NSString *)visualConstraint withBindings:(NSDictionary *)bindings {
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:visualConstraint
                                                                 options:0
                                                                 metrics:nil
                                                                   views:bindings]];
}

- (NSLayoutConstraint *)pinAttribute:(NSLayoutAttribute)attribute toSameOfView:(PLATFORMVIEW *)view {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self attribute:attribute relatedBy:NSLayoutRelationEqual toItem:view attribute:attribute multiplier:1 constant:0];
    [[self superview] addConstraint:constraint];
    return constraint;
}

- (NSArray *)centerInSuperview {
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObject:[self centerInSuperviewOnAxis:NSLayoutAttributeCenterX]];
    [constraints addObject:[self centerInSuperviewOnAxis:NSLayoutAttributeCenterY]];
    [self.superview addConstraints:constraints];
    return constraints;
}

- (NSLayoutConstraint *)centerInSuperviewOnAxis:(NSLayoutAttribute)axis {
    return [self pinAttribute:axis toSameOfView:self.superview];
}

- (NSArray *)stretchInSuperview {
    return [self stretchInSuperviewWithInset:PLATFORMINSETZERO];
}

- (NSArray *)pinInSuperviewToEdges:(PPViewEdge)edges withInset:(CGFloat)inset {
    PLATFORMVIEW *superview = self.superview;
    NSMutableArray *constraints = [NSMutableArray new];
    
    if (edges & PPViewEdgeTop) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                            attribute:NSLayoutAttributeTop
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:superview
                                                            attribute:NSLayoutAttributeTop
                                                           multiplier:1.0
                                                             constant:inset]];
    }
    if (edges & PPViewEdgeLeft) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                            attribute:NSLayoutAttributeLeft
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:superview
                                                            attribute:NSLayoutAttributeLeft
                                                           multiplier:1.0
                                                             constant:inset]];
    }
    if (edges & PPViewEdgeRight) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                            attribute:NSLayoutAttributeRight
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:superview
                                                            attribute:NSLayoutAttributeRight
                                                           multiplier:1.0
                                                             constant:-inset]];
    }
    if (edges & PPViewEdgeBottom) {
        [constraints addObject:[NSLayoutConstraint constraintWithItem:self
                                                            attribute:NSLayoutAttributeBottom
                                                            relatedBy:NSLayoutRelationEqual
                                                               toItem:superview
                                                            attribute:NSLayoutAttributeBottom
                                                           multiplier:1.0
                                                             constant:-inset]];
    }
    [superview addConstraints:constraints];
    return constraints;
}

- (NSLayoutConstraint *)pinEdge:(NSLayoutAttribute)edge toEdge:(NSLayoutAttribute)toEdge ofView:(PLATFORMVIEW *)view inset:(CGFloat)inset {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self
                                                                  attribute:edge
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:view
                                                                  attribute:toEdge
                                                                 multiplier:1.0
                                                                   constant:inset];
    [self.superview addConstraint:constraint];
    return constraint;
}

- (NSArray *)stretchInSuperviewWithInset:(PLATFORMINSETS)insets {
    NSMutableArray *constraints = [NSMutableArray new];
    [constraints addObjectsFromArray:[self pinInSuperviewToEdges:PPViewEdgeTop withInset:insets.top]];
    [constraints addObjectsFromArray:[self pinInSuperviewToEdges:PPViewEdgeLeft withInset:insets.left]];
    [constraints addObjectsFromArray:[self pinInSuperviewToEdges:PPViewEdgeRight withInset:insets.bottom]];
    [constraints addObjectsFromArray:[self pinInSuperviewToEdges:PPViewEdgeBottom withInset:insets.right]];
    return constraints;
}

- (NSLayoutConstraint *)constrainToWidth:(CGFloat)width {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self
                                                                  attribute:NSLayoutAttributeWidth
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:0
                                                                 multiplier:0
                                                                   constant:width];
    [self addConstraint:constraint];
    return constraint;
}

- (NSLayoutConstraint *)constrainToHeight:(CGFloat)height {
    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self
                                                                  attribute:NSLayoutAttributeHeight
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:nil
                                                                  attribute:0
                                                                 multiplier:0
                                                                   constant:height];
    [self addConstraint:constraint];
    return constraint;
}

- (CGFloat)frameWidth
{
    return self.frame.size.width;
}

- (void)setFrameWidth:(CGFloat)frameWidth
{
    CGRect frame = self.frame;
    frame.size.width = frameWidth;
    
    self.frame = frame;
}

- (CGFloat)frameHeight
{
    return self.frame.size.height;
}

- (void)setFrameHeight:(CGFloat)frameHeight
{
    CGRect frame = self.frame;
    frame.size.height = frameHeight;
    
    self.frame = frame;
}

-(CGFloat)frameTop {
    return self.frame.origin.y;
}

-(void)setFrameTop:(CGFloat)frameTop {
    CGRect frame = self.frame;
    frame.origin.y = frameTop;

    self.frame = frame;
}

-(CGFloat)frameLeft {
    return self.frame.origin.x;
}

-(void)setFrameLeft:(CGFloat)frameLeft {
    CGRect frame = self.frame;
    frame.origin.x = frameLeft;

    self.frame = frame;
}

- (CGFloat)frameMinX
{
    return CGRectGetMinX(self.frame);
}

- (void)setFrameMinX:(CGFloat)frameMinX
{
    CGRect frame = self.frame;
    frame.origin.x = frameMinX;
    
    self.frame = frame;
}

- (CGFloat)frameMidX
{
    return CGRectGetMidX(self.frame);
}

- (void)setFrameMidX:(CGFloat)frameMidX
{
    self.frameMinX = (frameMidX - roundf(self.frameWidth / 2.0f));
}

- (CGFloat)frameMaxX
{
    return CGRectGetMaxX(self.frame);
}

- (void)setFrameMaxX:(CGFloat)frameMaxX
{
    self.frameMinX = (frameMaxX - self.frameWidth);
}

- (CGFloat)frameMinY
{
    return CGRectGetMinY(self.frame);
}

- (void)setFrameMinY:(CGFloat)frameMinY
{
    CGRect frame = self.frame;
    frame.origin.y = frameMinY;
    
    self.frame = frame;
}

- (CGFloat)frameMidY
{
    return CGRectGetMidY(self.frame);
}

- (void)setFrameMidY:(CGFloat)frameMidY
{
    self.frameMinY = (frameMidY - roundf(self.frameHeight / 2.0f));
}

- (CGFloat)frameMaxY
{
    return CGRectGetMaxY(self.frame);
}

- (void)setFrameMaxY:(CGFloat)frameMaxY
{
    self.frameMinY = (frameMaxY - self.frameHeight);
}


@end
