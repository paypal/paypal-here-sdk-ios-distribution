//
//  PPSignatureView.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/26/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPSignatureView.h"

#define LINE_WIDTH 4.0f
#define LINE_COLOR [UIColor blackColor].CGColor
#define MIN_SIGNATURE_LENGTH 100.0f

@interface PPSignatureView ()
@property (nonatomic,assign) BOOL isEmpty;
@property (nonatomic,assign) CGMutablePathRef path;
@property (nonatomic,assign) CGPoint currentPoint;
@property (nonatomic,assign) CGPoint previousPoint1;
@property (nonatomic,assign) CGPoint previousPoint2;
@property (nonatomic,assign) CGPoint startPoint;
@property (nonatomic,assign) CGFloat pathLength;
@end

@implementation PPSignatureView

#pragma mark -
#pragma mark INIT

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self sharedInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit {
    self.userInteractionEnabled = YES;
    self.opaque = NO;
    [self resetPath];
}

-(void)dealloc {
    CGPathRelease(self.path);
}

#pragma mark -
#pragma mark DRAW FUNCTIONS

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self.delegate signatureTouchesBegan];

    UITouch *touch = [touches anyObject];
    self.previousPoint1 = [touch previousLocationInView:self];
    self.previousPoint2 = [touch previousLocationInView:self];
    self.currentPoint = [touch locationInView:self];
    self.startPoint = self.currentPoint;

    [self touchesMoved:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];

    CGPoint newPoint = [touch locationInView:self];
    CGFloat dx = newPoint.x - self.currentPoint.x;
    CGFloat dy = newPoint.y - self.currentPoint.y;
    self.pathLength += sqrtf(dx * dx + dy * dy);

    self.previousPoint2 = self.previousPoint1;
    self.previousPoint1 = [touch previousLocationInView:self];
    self.currentPoint = newPoint;

    CGPoint mid1 = PPmidPoint(self.previousPoint1, self.previousPoint2);
    CGPoint mid2 = PPmidPoint(self.currentPoint, self.previousPoint1);
    CGMutablePathRef subpath = CGPathCreateMutable();
    CGPathMoveToPoint(subpath, NULL, mid1.x, mid1.y);
    CGPathAddQuadCurveToPoint(subpath, NULL, self.previousPoint1.x, self.previousPoint1.y, mid2.x, mid2.y);
    CGRect bounds = CGPathGetBoundingBox(subpath);

    CGPathAddPath(_path, NULL, subpath);
    CGPathRelease(subpath);

    CGRect drawBox = bounds;
    drawBox.origin.x -= LINE_WIDTH * 2.0;
    drawBox.origin.y -= LINE_WIDTH * 2.0;
    drawBox.size.width += LINE_WIDTH * 4.0;
    drawBox.size.height += LINE_WIDTH * 4.0;

    [self setNeedsDisplayInRect:drawBox];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    // Can populate a Data array here to be used when the print button if fired
    if([self isEmptySignature]) {
        if(self.pathLength > MIN_SIGNATURE_LENGTH) {
            self.isEmpty = NO;
        }
    }
    [self.delegate signatureUpdated:[self isEmptySignature]];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextAddPath(context, self.path);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, LINE_WIDTH);
    CGContextSetStrokeColorWithColor(context, LINE_COLOR);
    CGContextStrokePath(context);
}

- (UIImage *)printableImage {
    // TODO only record the bounding rect
    // CGRect bound = CGPathGetPathBoundingBox(self.path);

    UIGraphicsBeginImageContext(self.bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, self.bounds);

    CGContextAddPath(context, self.path);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineWidth(context, LINE_WIDTH);
    CGContextSetStrokeColorWithColor(context, LINE_COLOR);
    CGContextStrokePath(context);

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

- (void)clearSignaturePad {
    [self resetPath];
    [self setNeedsDisplay];
}

- (void)resetPath {
    CGPathRelease(_path);
    _path = CGPathCreateMutable();
    _pathLength = 0.0f;
    _isEmpty = YES;
}

#pragma mark -
#pragma mark HELPER FUNCTION

-(BOOL)isEmptySignature {
    return _isEmpty;
}

CGPoint PPmidPoint(CGPoint p1, CGPoint p2) {
    return CGPointMake((p1.x + p2.x) * 0.5, (p1.y + p2.y) * 0.5);
}

@end
