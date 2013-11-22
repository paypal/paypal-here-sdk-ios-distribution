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
@property (nonatomic,strong) UIWindow *window;
@property (nonatomic,strong) UIView *overlayContainer;
@property (nonatomic,strong) UIView *currentOverlay;
@property (nonatomic, assign) CGAffineTransform rotationTransform;
@end

@implementation PPSMasterViewController
-(id)initWithWindow: (UIWindow*) window andViewController:(UIViewController *)controller
{
    if ((self = [super init])) {
        self.mainController = controller;
        self.window = window;
    }
    return self;
}

-(void)loadView
{
    self.edgesForExtendedLayout = UIRectEdgeNone;
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
    self.overlayContainer = [[UIView alloc] initWithFrame:self.window.bounds];
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

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
    [self setTransformForCurrentOrientation];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    [self setTransformForCurrentOrientation];
}

- (void)setTransformForCurrentOrientation {
    self.overlayContainer.bounds = self.window.bounds;
    [self.overlayContainer setNeedsDisplay];

    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    CGFloat radians = 0;
    self.overlayContainer.transform = CGAffineTransformIdentity;

    if (UIInterfaceOrientationIsLandscape(orientation)) {
        if (orientation == UIInterfaceOrientationLandscapeLeft) {
            radians = -(CGFloat)M_PI_2;
        } else {
            radians = (CGFloat)M_PI_2;
        }
        // Window coordinates differ!
        self.overlayContainer.bounds = CGRectMake(0, 0, self.overlayContainer.bounds.size.height, self.overlayContainer.bounds.size.width);

    } else {
        if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
            radians = (CGFloat)M_PI;
        } else {
            radians = 0;
        }
    }

    self.rotationTransform = CGAffineTransformMakeRotation(radians);

    self.overlayContainer.transform = self.rotationTransform;
    self.overlayContainer.frame = CGRectMake(0, 0, self.overlayContainer.frame.size.width, self.overlayContainer.frame.size.height);
}

// in a navigation controller subclass (the window's root view controller)
- (UIStatusBarStyle)preferredStatusBarStyle {
    if (self.mainController) {
        // ask whatever view controller is currently visible for the current status bar style
        return [self.mainController preferredStatusBarStyle];
    }
    return UIStatusBarStyleLightContent;
}

@end
