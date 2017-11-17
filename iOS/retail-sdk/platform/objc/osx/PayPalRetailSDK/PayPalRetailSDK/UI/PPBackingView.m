//
//  PPBackingView.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/24/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPBackingView.h"

@implementation PPBackingView

- (void)drawRect:(NSRect)dirtyRect {
    // set any NSColor for filling, say white:
    [self.backgroundColor setFill];
    NSRectFillUsingOperation(dirtyRect, NSCompositeSourceOver);
    [super drawRect:dirtyRect];
}

@end
