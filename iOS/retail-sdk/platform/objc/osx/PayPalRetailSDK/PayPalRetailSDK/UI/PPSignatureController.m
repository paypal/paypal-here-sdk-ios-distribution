//
//  PPSignatureView.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/25/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPSignatureController.h"
#import "PayPalRetailSDK+Private.h"
#import "PayPalRetailSDKStyles.h"

#define LINE_WIDTH 4.0f
#define LINE_COLOR [NSColor blackColor].CGColor
#define MIN_SIGNATURE_LENGTH 100.0f

@interface PPPathView : NSView
@property (nonatomic,assign) BOOL isEmpty;
@property (nonatomic,assign) CGMutablePathRef path;
@property (nonatomic,assign) CGPoint currentPoint;
@property (nonatomic,assign) CGPoint previousPoint1;
@property (nonatomic,assign) CGPoint previousPoint2;
@property (nonatomic,assign) CGPoint startPoint;
@property (nonatomic,assign) CGFloat pathLength;
-(void)resetPath;
@end

@interface PPSignatureController ()
@property (nonatomic,strong) PPPathView *signatureView;
@property (nonatomic,strong) NSButton *doneButton;
@property (nonatomic,strong) NSButton *clearButton;
@property (nonatomic,strong) JSValue *callback;
@property (nonatomic,strong) NSWindow *owner;
@end

CGPoint midPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

@implementation PPSignatureController

+(PPSignatureController *)signatureView:(JSValue *)options withCallback:(JSValue *)callback {
    __block PPSignatureController *signatureView = [[PPSignatureController alloc] initWithWindow:[NSApp mainWindow] andCallback:callback];
    [[NSApp mainWindow] beginCriticalSheet:signatureView completionHandler:^(NSModalResponse returnCode) {

    }];
    return signatureView;
}

-(instancetype)initWithWindow:(NSWindow *)window andCallback:(JSValue*)callback {
    NSRect wrect = window.frame;
    if (window.titleVisibility == NSWindowTitleVisible) {
        wrect.size.height -= wrect.size.height - [window.contentView frame].size.height;
    }
    if ((self = [super initWithContentRect:wrect styleMask:NSBorderlessWindowMask backing:
                 NSBackingStoreBuffered defer:NO])) {
        self.owner = window;
        self.callback = callback;
        self.signatureView = [[PPPathView alloc] initWithFrame:self.contentLayoutRect];
        [self.signatureView resetPath];
        [self.signatureView setWantsLayer:YES];
        self.signatureView.layer.backgroundColor = [PayPalRetailSDKStyles viewBackgroundColor].CGColor;
        [self.contentView addSubview:self.signatureView];

        self.doneButton = [[NSButton alloc] initWithFrame:NSMakeRect(self.contentLayoutRect.size.width - 80, self.contentLayoutRect.size.height - 64, 60, 44)];
        [self.doneButton setTarget:self];
        [self.doneButton setAction:@selector(donePressed)];
        // TODO take options form the native call
        self.doneButton.title = @"Done";
        [self.signatureView addSubview:self.doneButton];
    }
    return self;
}

-(void)donePressed {
    NSRect bounding = CGPathGetPathBoundingBox(self.signatureView.path);
    if (bounding.size.width == 0 || bounding.size.height == 0) {
        NSAssert(NO, @"Should not have been able to press the done button on signature page without a signature path.");
        return;
    }
    bounding.origin.x = floorf(bounding.origin.x);
    bounding.origin.y = floorf(bounding.origin.y);
    bounding.size.width = ceilf(bounding.size.width);
    bounding.size.height = ceilf(bounding.size.height);

    CGContextRef context = CGBitmapContextCreate(0, bounding.size.width, bounding.size.height, 8, bounding.size.width, [NSColorSpace genericGrayColorSpace].CGColorSpace, kCGBitmapByteOrderDefault);

    CGContextSetFillColorWithColor(context, [NSColor whiteColor].CGColor);
    CGContextFillRect(context, NSMakeRect(0, 0, bounding.size.width, bounding.size.height));

    CGContextMoveToPoint(context, -bounding.origin.x, -bounding.origin.y);
    CGContextAddPath(context, self.signatureView.path);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, LINE_WIDTH);
    CGContextSetStrokeColorWithColor(context, LINE_COLOR);
    CGContextStrokePath(context);

    CGImageRef imageRef = CGBitmapContextCreateImage(context);
    NSImage* image = [[NSImage alloc] initWithCGImage:imageRef size:bounding.size];
    CFRelease(imageRef);
    CFRelease(context);

    NSData *imageData = [image TIFFRepresentation];
    NSBitmapImageRep *imageRep = [NSBitmapImageRep imageRepWithData:imageData];
    NSNumber *compressionFactor = [NSNumber numberWithFloat:0.9];
    NSDictionary *imageProps = [NSDictionary dictionaryWithObject:compressionFactor
                                                           forKey:NSImageCompressionFactor];
    imageData = [imageRep representationUsingType:NSJPEGFileType properties:imageProps];

    [self.callback callWithArguments:@[[NSNull null],[imageData base64EncodedStringWithOptions:0]]];
    self.callback = nil;
    [self.owner endSheet:self];
}

-(void)mouseDragged:(NSEvent *)theEvent {
    CGPoint newPoint = [theEvent locationInWindow];
    CGFloat dx = newPoint.x - self.signatureView.currentPoint.x;
    CGFloat dy = newPoint.y - self.signatureView.currentPoint.y;
    self.signatureView.pathLength += sqrtf(dx * dx + dy * dy);

    self.signatureView.previousPoint2 = self.signatureView.previousPoint1;
    self.signatureView.previousPoint1 = self.signatureView.currentPoint;
    self.signatureView.currentPoint = newPoint;

    CGPoint mid1 = midPoint(self.signatureView.previousPoint1, self.signatureView.previousPoint2);
    CGPoint mid2 = midPoint(self.signatureView.currentPoint, self.signatureView.previousPoint1);
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL, self.signatureView.previousPoint1.x, self.signatureView.previousPoint1.y, mid2.x, mid2.y);
    CGRect bounds = CGPathGetBoundingBox(subpath);

    CGPathAddPath(self.signatureView.path, NULL, subpath);
    CGPathRelease(subpath);

    CGRect drawBox = bounds;
    drawBox.origin.x -= LINE_WIDTH * 2.0;
    drawBox.origin.y -= LINE_WIDTH * 2.0;
    drawBox.size.width += LINE_WIDTH * 4.0;
    drawBox.size.height += LINE_WIDTH * 4.0;

    [self.signatureView setNeedsDisplayInRect:drawBox];
}

-(void)mouseDown:(NSEvent *)theEvent {
    self.signatureView.previousPoint1 = [theEvent locationInWindow];
    self.signatureView.previousPoint2 = [theEvent locationInWindow];
    self.signatureView.currentPoint = [theEvent locationInWindow];
    self.signatureView.startPoint = self.signatureView.currentPoint;
}

-(void)mouseUp:(NSEvent *)theEvent {

}

@end

@implementation  PPPathView

-(void)dealloc {
    CGPathRelease(_path);
}

-(void)drawRect:(NSRect)dirtyRect {
    CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
    CGContextAddPath(context, self.path);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, LINE_WIDTH);
    CGContextSetStrokeColorWithColor(context, LINE_COLOR);
    CGContextStrokePath(context);
}

- (void)clearSignaturePad {
    [self resetPath];
    [self setNeedsDisplay:YES];
}

- (void)resetPath {
    CGPathRelease(self.path);
    self.path = CGPathCreateMutable();
    self.pathLength = 0.0f;
    self.isEmpty = YES;
}

@end