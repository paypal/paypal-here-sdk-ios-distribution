//
//  PPAlertView.m
//  PayPalRetailSDK
//
//  Created by Max Metral on 4/3/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPAlertView.h"
#import "PayPalRetailSDKStyles.h"
#import "PlatformView+PPAutoLayout.h"
#import "UIButton+PPStyle.h"

#define BUTTON_MOD 9000


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPAlertView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIView *customView;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIActivityIndicatorView *spinner;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, copy) PPAlertViewSelectionBlock selectionHandler;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) NSMutableArray *viewsAndSpacers;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PPAlertView

#pragma mark -
#pragma mark Init & Factory
+ (PPAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                  cancelButtonTitle:(NSString *)cancelButtonTitle
                  otherButtonTitles:(NSArray *)otherButtonTitles
                   selectionHandler:(PPAlertViewSelectionBlock)selectionHandler {
    return [self showAlertWithTitle:title
                            message:message
                  cancelButtonTitle:cancelButtonTitle
                  otherButtonTitles:otherButtonTitles
                       showActivity:NO
                   selectionHandler:selectionHandler];
    
}

+ (PPAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                  cancelButtonTitle:(NSString *)cancelButtonTitle
                  otherButtonTitles:(NSArray *)otherButtonTitles
                       showActivity:(BOOL)showActivity
                   selectionHandler:(PPAlertViewSelectionBlock)selectionHandler {
    return [self showAlertWithTitle:title
                            message:message
                               view:nil
                  cancelButtonTitle:cancelButtonTitle
                  otherButtonTitles:otherButtonTitles
                       showActivity:showActivity
                   selectionHandler:selectionHandler];
}

+ (PPAlertView *)showAlertWithView:(UIView *)customView
                 cancelButtonTitle:(NSString *)cancelButtonTitle
                 otherButtonTitles:(NSArray *)otherButtonTitles
                  selectionHandler:(PPAlertViewSelectionBlock)selectionHandler {
    return [self showAlertWithTitle:nil
                            message:nil
                               view:customView
                  cancelButtonTitle:cancelButtonTitle
                  otherButtonTitles:otherButtonTitles
                       showActivity:NO
                   selectionHandler:selectionHandler];
}

+ (PPAlertView *)showAlertWithTitle:(NSString *)title
                            message:(NSString *)message
                               view:(UIView *)customView
                  cancelButtonTitle:(NSString *)cancelButtonTitle
                  otherButtonTitles:(NSArray *)otherButtonTitles
                       showActivity:(BOOL)showActivity
                   selectionHandler:(PPAlertViewSelectionBlock)selectionHandler {
    
    PPAlertView *alertView = [[self alloc] initWithTitle:title
                                                 message:message
                                                    view:customView
                                       cancelButtonTitle:cancelButtonTitle
                                       otherButtonTitles:otherButtonTitles
                                            showActivity:showActivity
                                        selectionHandler:selectionHandler];
    return alertView;
}

- (id)initWithTitle:(NSString *)title
            message:(NSString *)message
               view:(UIView *)customView
  cancelButtonTitle:(NSString *)cancelButtonTitle
  otherButtonTitles:(NSArray *)otherButtonTitles
       showActivity:(BOOL)showActivity
   selectionHandler:(PPAlertViewSelectionBlock)selectionHandler {

    self = [super initWithFrame:CGRectZero];
    
    if (self) {
        [self setBackgroundColor:[PayPalRetailSDKStyles viewBackgroundColor]];
        
        UIWindow *window = [[UIApplication sharedApplication] keyWindow];
        self.maskView = [[UIView alloc] initWithFrame:CGRectMake(-100000, -100000, 1000000, 1000000)];
        self.maskView.backgroundColor = [PayPalRetailSDKStyles screenMaskColor];
        self.maskView.userInteractionEnabled = YES;
        [window addSubview:self.maskView];
        [window addSubview:self];
        [window endEditing:YES];
        self.selectionHandler = selectionHandler;
        self.accessibilityIdentifier = @"PPHAlert View";
        self.layer.cornerRadius = 6;
        
        //This is an array of arrays containg a view and its spacing below the previous view @[[UIView, NSNumber]...]
        self.viewsAndSpacers = [NSMutableArray new];
        [self setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self constrainToWidth:288];
        
        // CustomView
        if (customView) {
            self.customView = customView;
            [self.customView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.customView constrainToHeight:customView.frameHeight];
            [self.customView constrainToWidth:customView.frameWidth];
            [self.viewsAndSpacers addObject:@[self.customView, @16.0f]];
            [self addSubview:self.customView];
        }
        
        // Title
        if (title) {
            self.titleLabel = [self defaultStyledLabelWithFont:[[PayPalRetailSDKStyles font] fontWithSize:35]];
            self.titleLabel.text = title;
            [self.titleLabel constrainToWidth:256];
            [self.titleLabel sizeToFit];
            [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.viewsAndSpacers addObject:@[self.titleLabel, @18.0f]];
            [self addSubview:self.titleLabel];
        }
        
        // Spinner
        if (showActivity) {
            self.spinner = [UIActivityIndicatorView new];
            self.spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
            [self.spinner startAnimating];
            [self.spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.viewsAndSpacers addObject:@[self.spinner, @18.0f]];
            [self addSubview:self.spinner];
        }
        
        // Message
        if (message) {
            self.messageLabel = [self defaultStyledLabelWithFont:[PayPalRetailSDKStyles font]];
            self.messageLabel.text = message;
            [self.messageLabel constrainToWidth:256];
            [self.messageLabel sizeToFit];
            [self.messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.viewsAndSpacers addObject:@[self.messageLabel, @18.0f]];
            [self addSubview:self.messageLabel];
        }
        
        NSMutableArray *allButtonTitles = [NSMutableArray arrayWithArray:otherButtonTitles];
        if (cancelButtonTitle) {
            [allButtonTitles addObject:cancelButtonTitle];
        }
        
        if (allButtonTitles.count) {
            UIView *spacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frameWidth, 17)];
            [spacerView setBackgroundColor:[UIColor clearColor]];
            [spacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
            [self.viewsAndSpacers addObject:@[spacerView, @0.0f]];
            [self addSubview:spacerView];
        }
        
        // Buttons
        [allButtonTitles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            UIButton *newbutton;
            if (idx == allButtonTitles.count -1 && cancelButtonTitle) {
                newbutton = [[UIButton PPButton] PPButtonSecondary];
                self.cancelButtonIndex = idx;
            } else {
                newbutton = [[UIButton PPButton] PPButtonPrimary];
            }
            newbutton.tag = BUTTON_MOD + idx;
            [newbutton setTitle:obj forState:UIControlStateNormal];
            [newbutton addTarget:self action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
            [newbutton setTranslatesAutoresizingMaskIntoConstraints:NO];
            [newbutton setFrameHeight:44];
            [newbutton constrainToHeight:44];
            [newbutton constrainToWidth:256];
            [self.viewsAndSpacers addObject:@[newbutton, @9.0f]];
            [self addSubview:newbutton];
        }];
        
        UIView *bottomSpacerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, 16)];
        [self setBackgroundColor:[UIColor whiteColor]];
        [bottomSpacerView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [bottomSpacerView constrainToHeight:16];
        [bottomSpacerView constrainToWidth:self.frameWidth];
        [self.viewsAndSpacers addObject:@[bottomSpacerView, @0.0f]];
        [self addSubview:bottomSpacerView];
        
        UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        [self rotateToOrientation:orientation];
        
        CGFloat heightConstraint = 0.0;
        for (NSArray *viewAndSpacing in self.viewsAndSpacers) {
            UIView *view = (UIView *)viewAndSpacing[0];
            NSNumber *spacing = (NSNumber *)viewAndSpacing[1];
            heightConstraint = heightConstraint + view.frameHeight + spacing.floatValue;
        }
        [self constrainToHeight:heightConstraint];
        [self centerInSuperview];
    }
    
    return self;
}

- (UILabel *)defaultStyledLabelWithFont:(UIFont *)font {
    UILabel *label = [UILabel new];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [PayPalRetailSDKStyles primaryTextColor];
    label.backgroundColor = [UIColor clearColor];
    label.font = font;
    return label;
}

- (void)updateConstraints {
    UIView *previousView;
    for (NSArray *viewAndSpacing in self.viewsAndSpacers) {
        UIView *view = (UIView *)viewAndSpacing[0];
        NSNumber *spacing = (NSNumber *)viewAndSpacing[1];
        if (previousView) {
            [view pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:previousView inset:spacing.floatValue];
        } else {
            [view pinInSuperviewToEdges:PPViewEdgeTop withInset:spacing.floatValue];
        }
        previousView = view;
        [view centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
    }
    [super updateConstraints];
}

#pragma mark -
#pragma mark PPAlertView
- (void)buttonSelected:(UIButton *)sender {
    if (self.selectionHandler) {
        self.selectionHandler(self, sender.tag - BUTTON_MOD);
    }
    
    [self dismissAnimated:YES];
}

#pragma mark -
#pragma mark PPAlertView Public

- (void)dismissAnimated:(BOOL)animated {
    [self.maskView removeFromSuperview];
    [self removeFromSuperview];
}


- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self setNeedsLayout];
}

- (void)setMessage:(NSString *)message {
    self.messageLabel.text = message;
    [self setNeedsLayout];
}

- (void)setTitle:(NSString *)title message:(NSString *)message {
    [self setTitle:title];
    [self setMessage:message];
}

#pragma mark -
#pragma mark UIView
- (void)layoutSubviews {
    if (self.customView) {
        [self.customView setNeedsLayout];
        [self.customView layoutIfNeeded];
    }
    
    [super layoutSubviews];
}

- (void)rotateToOrientation:(UIInterfaceOrientation)toOrientation {
    
    if (!([[[UIDevice currentDevice] systemVersion] compare:@"8.0" options:NSNumericSearch] != NSOrderedAscending)) {
        
        CGFloat radians = 0;
        
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
        // Transforms/rotates the whitish background of the alert ui.
        self.transform = CGAffineTransformMakeRotation(radians);
        // Changes the orientation of the text and the background of the alert ui.
        self.desiredOrientation = toOrientation;
        
        [self setNeedsLayout];
        
    } else {
        self.desiredOrientation = toOrientation;
        [self layoutSubviews];
    }
}


@end
