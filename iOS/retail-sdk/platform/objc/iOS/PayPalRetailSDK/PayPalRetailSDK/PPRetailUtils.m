//
//  PPRetailUtils.m
//  Pods
//
//  Created by Chandrashekar, Sathyanarayan on 6/7/17.
//
//

#import "PPRetailUtils.h"
#import <objc/runtime.h>

#define IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
static char ppRetailPresentedViewOnWindowKey = 0;

@interface UIWindow (PPRotation)

- (void)addAndOrientSubview:(nonnull UIView *)view;

@end

@interface UIView (PPRotation)

- (void)rotateToCurrentOrientation;

@end

@implementation UIWindow (PPRotation)

- (void)addAndOrientSubview:(nonnull UIView *)view {
    if (!IOS_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")) {
        [view rotateToCurrentOrientation];
    }
    [self addSubview:view];
}

@end

@interface UIView (PPRotation)

@end

@implementation UIView (PPRotation)

- (void)rotateToCurrentOrientation {
    [self rotateToOrientation: [UIApplication sharedApplication].statusBarOrientation];
}

- (void)rotateToOrientation: (UIInterfaceOrientation)toOrientation {
    CGFloat radians = 0;
    if (toOrientation == UIInterfaceOrientationUnknown) {
        toOrientation = [UIApplication sharedApplication].statusBarOrientation;
    }
    
    if (UIInterfaceOrientationIsLandscape(toOrientation)) {
        if (toOrientation == UIInterfaceOrientationLandscapeLeft) {
            radians = -(CGFloat)M_PI_2;
        } else {
            radians = (CGFloat)M_PI_2;
        }
    } else {
        if (toOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            radians = (CGFloat)M_PI;
        } else {
            radians = 0;
        }
    }
    
    self.transform = CGAffineTransformMakeRotation(radians);
    [self setNeedsLayout];
}

@end

@implementation PPRetailUtils

+ (void)dispatchOnMainThread:(void(^)(void))block {
    if (block) {
        dispatch_async(dispatch_get_main_queue(), ^{
            block();
        });
    }
}

+ (void)completeWithCallback:(JSValue *)callback arguments:(NSArray *)arguments {
    if (!callback.isNull && !callback.isUndefined) {
        [callback callWithArguments:arguments];
    }
}

+ (void)displayAlertView:(UIView *)alertView {
    BOOL presentedOnWindow = YES;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [window addAndOrientSubview:alertView];
    [window endEditing:YES];
    objc_setAssociatedObject(alertView, &ppRetailPresentedViewOnWindowKey, @(presentedOnWindow), OBJC_ASSOCIATION_RETAIN);
}

+ (void)dismissAlertView:(UIView *)alertView {
    BOOL presentedOnWindow = [objc_getAssociatedObject(alertView, &ppRetailPresentedViewOnWindowKey) boolValue];
    if (presentedOnWindow) {
        [alertView removeFromSuperview];
    }
}


@end



