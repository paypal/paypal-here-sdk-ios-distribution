//
//  PPSMasterViewController.m
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PPSMasterViewController.h"

@interface PPSMasterViewController ()
{
    CGAffineTransform rotationTransform;
}
@property (nonatomic,strong) UIView *overlayContainer;
@property (nonatomic,strong) UIView *currentOverlay;
@end

@implementation PPSMasterViewController
-(id)initWithViewController:(UIViewController *)controller
{
    if ((self = [super init])) {
        self.mainController = controller;
    }
    return self;
}

-(void)loadView
{
    [super loadView];
    [self.view addSubview:self.mainController.view];
    [self addChildViewController:self.mainController];
}

-(void)viewWillLayoutSubviews
{
  [super viewWillLayoutSubviews];
  self.mainController.view.frame = self.view.bounds;
}

#pragma mark - Overlay Handling

-(BOOL)addOverlayView:(UIView *)view withMask:(BOOL)addInputMask
       removeExisting:(BOOL)removeExisting animated:(BOOL)animated
{
    if (self.overlayContainer && !removeExisting) {
        return NO;
    }
    if (self.overlayContainer) {
        // One is already up, so just do a quick fade
        if (animated) {
            view.alpha = 0;
            [self.overlayContainer addSubview:view];
            [UIView animateWithDuration:0.1 animations:^{
                view.alpha = 1.0;
                self.currentOverlay.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self.currentOverlay removeFromSuperview];
                self.currentOverlay = view;
                self.overlayContainer.backgroundColor = addInputMask ? [UIColor colorWithWhite:.1 alpha:0.5] : [UIColor clearColor];
                self.overlayContainer.userInteractionEnabled = !addInputMask;
            }];
        } else {
            [self.currentOverlay removeFromSuperview];
            [self.overlayContainer addSubview:view];
            self.overlayContainer.backgroundColor = addInputMask ? [UIColor colorWithWhite:.1 alpha:0.5] : [UIColor clearColor];
            self.overlayContainer.userInteractionEnabled = !addInputMask;
            self.currentOverlay = view;
        }
        return YES;
    }
    
    UIWindow *w = [[UIApplication sharedApplication].windows lastObject];
    self.overlayContainer = [[UIView alloc] initWithFrame:w.bounds];
    if (w == [PPSAppDelegate appDelegate].window) {
        [self setTransformForCurrentOrientation:NO];
    }

    if (animated) {
        self.overlayContainer.alpha = 0;
    }
    [w addSubview:self.overlayContainer];
    [self.overlayContainer addSubview: view];
    [w bringSubviewToFront:self.overlayContainer];

    if (addInputMask) {
        self.overlayContainer.backgroundColor = [UIColor colorWithWhite:.1 alpha:0.5];
        self.overlayContainer.userInteractionEnabled = YES;
    } else {
        self.overlayContainer.backgroundColor = [UIColor clearColor];
        self.overlayContainer.userInteractionEnabled = NO;
    }

    if (animated) {
        [UIView animateWithDuration:0.25 animations:^{
            self.overlayContainer.alpha = 1.0;
        } completion:^(BOOL finished) {
            
        }];
    }

    return YES;
}

-(void)removeOverlayView: (BOOL) animated
{
    if (self.overlayContainer && animated) {
        __block UIView *ol = self.overlayContainer;
        self.overlayContainer = nil;
        [UIView animateWithDuration:0.25 animations:^{
            ol.alpha = 0;
        } completion:^(BOOL finished) {
            [ol removeFromSuperview];
            ol = nil;
        }];
    } else {
        [self.overlayContainer removeFromSuperview];
        self.overlayContainer = nil;
    }
}

-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    if (self.overlayContainer.superview == [PPSAppDelegate appDelegate].window) {
        [self setTransformForCurrentOrientation:YES];
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    if (self.overlayContainer.superview == [PPSAppDelegate appDelegate].window) {
        [self setTransformForCurrentOrientation:NO];
    }
}

- (void)setTransformForCurrentOrientation:(BOOL)animated {
    if (!self.overlayContainer) {
        return;
    }
	// Stay in sync with the superview
    self.overlayContainer.bounds = self.view.superview.bounds;
    [self.overlayContainer setNeedsDisplay];
    
	UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
	CGFloat radians = 0;
	if (UIInterfaceOrientationIsLandscape(orientation)) {
		if (orientation == UIInterfaceOrientationLandscapeLeft) { radians = -(CGFloat)M_PI_2; }
		else { radians = (CGFloat)M_PI_2; }
		// Window coordinates differ!
		self.overlayContainer.bounds = CGRectMake(0, 0, self.overlayContainer.bounds.size.height, self.overlayContainer.bounds.size.width);
	} else {
		if (orientation == UIInterfaceOrientationPortraitUpsideDown) { radians = (CGFloat)M_PI; }
		else { radians = 0; }
	}
	rotationTransform = CGAffineTransformMakeRotation(radians);
    
	if (animated) {
		[UIView beginAnimations:nil context:nil];
	}
	self.overlayContainer.transform = rotationTransform;
	if (animated) {
		[UIView commitAnimations];
	}
}

@end
