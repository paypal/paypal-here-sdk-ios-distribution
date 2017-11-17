//
//  PPAlertView.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/4/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPAlertView.h"
#import "PayPalRetailSDK+Private.h"
#import "PayPalRetailSDKStyles.h"
#import <QuartzCore/QuartzCore.h>
#import "PlatformView+PPAutoLayout.h"
#import "PPBackingView.h"

@interface PPAlertView ()
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) PPBackingView *buttonSpacer;
@property (nonatomic, strong) NSView *bottomSpacer;
@property (nonatomic, strong) NSView *alertBackground;
@property (nonatomic, strong) NSTextField *titleLabel;
@property (nonatomic, strong) NSView *customView;
@property (nonatomic, strong) NSTextField *messageLabel;
@property (nonatomic, strong) NSProgressIndicator *spinner;
@property (nonatomic, strong) NSMutableArray *viewsAndSpacers;
@end

#define BUTTON_MOD 9000

static PPAlertView *singleton;
static BOOL isShowing;

// TODO this has become a Frankenstein with the switch from instance to singleton behavior... We should rewrite from scratch, and preferably someone who understands Mac Cocoa

@implementation PPAlertView
+(PPAlertView *)showAlertWithTitle:(NSString *)title message:(NSString *)message cancelButtonTitle:(NSString *)cancelButtonTitle otherButtonTitles:(NSArray *)otherButtonTitles showActivity:(BOOL)showActivity selectionHandler:(PPAlertViewSelectionBlock)selectionHandler {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[PPAlertView alloc] initSingleton:[NSApp mainWindow]];
    });
    [singleton configureWithWindow: [NSApp mainWindow] andTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitles:otherButtonTitles showActivity:showActivity selectionHandler:selectionHandler];
    if (!isShowing) {
        isShowing = YES;
        [[NSApp mainWindow] beginCriticalSheet:singleton completionHandler:^(NSModalResponse returnCode) {
            isShowing = NO;
        }];
    }
    // TODO return a proxy that will make sure these aren't called out of order
    return singleton;
}

- (id)initSingleton:(NSWindow*)window {
    NSRect wrect = window.frame;
    if (window.titleVisibility == NSWindowTitleVisible) {
        wrect.size.height -= wrect.size.height - [window.contentView frame].size.height;
    }
    if ((self = [super initWithContentRect:wrect styleMask:NSBorderlessWindowMask backing:NSBackingStoreBuffered defer:NO])) {
        
        self.alertBackground = [[NSView alloc] initWithFrame:self.contentLayoutRect];
        [self.alertBackground setWantsLayer:YES];
        self.alertBackground.layer.backgroundColor = [PayPalRetailSDKStyles viewBackgroundColor].CGColor;
        self.alertBackground.layer.cornerRadius = 6.0;
        [self.contentView addSubview:self.alertBackground];
        
        self.accessibilityIdentifier = @"PPHAlert View";
        self.backgroundColor = [PayPalRetailSDKStyles screenMaskColor];
        self.opaque = NO;
        
        self.alertBackground.frameWidth = 288;
        
        [self.contentView setTranslatesAutoresizingMaskIntoConstraints:NO];
        
        //This is an array of arrays containg a view and its spacing below the previous view @[[UIView, NSNumber]...]
        self.viewsAndSpacers = [NSMutableArray new];
        
        // Title
        self.titleLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
        self.titleLabel.drawsBackground = self.titleLabel.bezeled = self.titleLabel.editable = self.titleLabel.selectable = NO;
        self.titleLabel.font = [NSFont fontWithDescriptor:[PayPalRetailSDKStyles font].fontDescriptor size:35];
        self.titleLabel.preferredMaxLayoutWidth = 256;
        [self.titleLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.alertBackground addSubview:self.titleLabel];
        
        // Spinner
        self.spinner = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(0, 0, 30, 30)];
        self.spinner.style = NSProgressIndicatorSpinningStyle;
        [self.spinner setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.alertBackground addSubview:self.spinner];
        
        // Message
        self.messageLabel = [[NSTextField alloc] initWithFrame:NSZeroRect];
        self.messageLabel.drawsBackground = self.messageLabel.bezeled = self.messageLabel.editable = self.messageLabel.selectable = NO;
        self.messageLabel.font = [PayPalRetailSDKStyles font];
        self.messageLabel.preferredMaxLayoutWidth = 256;
        [self.messageLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.alertBackground addSubview:self.messageLabel];
        
        self.buttonSpacer = [[PPBackingView alloc] initWithFrame:NSMakeRect(0, 0, self.alertBackground.frameWidth, 17)];
        [self.buttonSpacer setBackgroundColor:[NSColor clearColor]];
        [self.buttonSpacer setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.alertBackground addSubview:self.buttonSpacer];
        
        self.bottomSpacer = [[NSView alloc] initWithFrame:CGRectMake(0, 0, 0, 32)];
        
        // TODO probably can just modify the layout loop instead of making this fake view
        [self.bottomSpacer setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.bottomSpacer constrainToHeight:16];
        [self.bottomSpacer constrainToWidth:self.contentLayoutRect.size.width];
        
        self.buttons = [NSMutableArray new];
    }
    return self;
}

- (void)configureWithWindow:(NSWindow*)window
                 andTitle:(NSString *)title
                  message:(NSString *)message
        cancelButtonTitle:(NSString *)cancelButtonTitle
        otherButtonTitles:(NSArray *)otherButtonTitles
             showActivity:(BOOL)showActivity
         selectionHandler:(PPAlertViewSelectionBlock)selectionHandler {
    
    [self.viewsAndSpacers removeAllObjects];
    
    self.selectionHandler = selectionHandler;
    
    self.titleLabel.hidden = !title;
    if (title) {
        self.titleLabel.stringValue = title;
        [self.titleLabel sizeToFit];
        [self.viewsAndSpacers addObject:@[self.titleLabel, @18.0f]];
    }
    
    // Spinner
    self.spinner.hidden = !showActivity;
    if (showActivity) {
        [self.spinner startAnimation:self];
        [self.viewsAndSpacers addObject:@[self.spinner, @18.0f]];
    } else {
        [self.spinner stopAnimation:self];
    }
    
    // Message
    self.messageLabel.hidden = !message;
    if (message) {
        self.messageLabel.stringValue = message;
        [self.messageLabel sizeToFit];
        [self.viewsAndSpacers addObject:@[self.messageLabel, @18.0f]];
    }
    
    NSMutableArray *allButtonTitles = [NSMutableArray arrayWithArray:otherButtonTitles];
    if (cancelButtonTitle) {
        [allButtonTitles addObject:cancelButtonTitle];
    }
    
    // Remove all existing buttons
    [self.buttons enumerateObjectsUsingBlock:^(NSView *btn, NSUInteger idx, BOOL *stop) {
        [btn removeFromSuperview];
    }];
    [self.buttons removeAllObjects];
    
    self.buttonSpacer.hidden = allButtonTitles.count == 0;
    if (allButtonTitles.count) {
        [self.viewsAndSpacers addObject:@[self.buttonSpacer, @0.0f]];
    }
    
    // Buttons
    [allButtonTitles enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSButton *newbutton;
        if (idx == allButtonTitles.count - 1 && cancelButtonTitle) {
            newbutton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 256, 44)];
            self.cancelButtonIndex = idx;
        } else {
            newbutton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 256, 44)];
        }
        [self.buttons addObject:newbutton];
        newbutton.tag = BUTTON_MOD + idx;
        newbutton.title = obj;
        [newbutton setTarget:self];
        [newbutton setAction:@selector(buttonSelected:)];
        [newbutton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.viewsAndSpacers addObject:@[newbutton, @9.0f]];
        [self.alertBackground addSubview:newbutton];
    }];
    
    [self.viewsAndSpacers addObject:@[self.bottomSpacer, @0.0f]];
    
    [self updateLayout];
}

-(void)buttonSelected:(NSButton *)sender {
    if (self.selectionHandler) {
        self.selectionHandler(self, sender.tag - BUTTON_MOD);
        self.selectionHandler = nil;
    }
}

-(void)updateLayout {
    // TODO this is just bad. I can't get constraints to work, so this is a manual flow layout and a confusing one at that.
    CGFloat heightConstraint = 18.0f;
    for (NSArray *viewAndSpacing in self.viewsAndSpacers) {
        NSView *view = (NSView *)viewAndSpacing[0];
        NSNumber *spacing = (NSNumber *)viewAndSpacing[1];
        heightConstraint = heightConstraint + view.frameHeight + spacing.floatValue;
    }
    self.alertBackground.frameHeight = heightConstraint;
    CGFloat topSpot = heightConstraint - 36.0f;
    for (NSArray *viewAndSpacing in self.viewsAndSpacers) {
        NSView *view = (NSView *)viewAndSpacing[0];
        NSNumber *spacing = (NSNumber *)viewAndSpacing[1];
        view.frameTop = topSpot - spacing.floatValue;
        view.frameLeft = (self.alertBackground.frameWidth - view.frameWidth) / 2.0;
        topSpot -= view.frameHeight + spacing.floatValue;
    }
    
    NSRect alertFrame = self.alertBackground.frame;
    NSRect cvFrame = [self.contentView frame];
    
    alertFrame.origin.x = (cvFrame.size.width - alertFrame.size.width) / 2;
    alertFrame.origin.y = (cvFrame.size.height - alertFrame.size.height) / 2;
    self.alertBackground.frame = alertFrame;
}

#pragma mark -
#pragma mark PPAlertView Public

- (void)dismissAnimated:(BOOL)animated {
    [[NSApp mainWindow] endSheet:self];
    isShowing = NO;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.stringValue = title;
    [self.titleLabel sizeToFit];
    [self updateLayout];
}

- (void)setMessage:(NSString *)message {
    self.messageLabel.stringValue = message;
    [self.messageLabel sizeToFit];
    [self updateLayout];
}

-(void)setTitle:(NSString *)title message:(NSString *)message {
    self.titleLabel.stringValue = title;
    [self.titleLabel sizeToFit];
    self.messageLabel.stringValue = message;
    [self.messageLabel sizeToFit];
    [self updateLayout];
}

@end
