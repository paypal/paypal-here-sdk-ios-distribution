//
//  PPSAlertView.m
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSAlertView.h"
#import "NICSSRuleset.h"
#import "NIStylesheet.h"
#import "UIView+NIStyleable.h"

@interface PPSAlertView ()
@property (nonatomic,strong) NIStylesheet *stylesheet;
@property (nonatomic,strong) UILabel *titleLabel;
@property (nonatomic,strong) UILabel *messageLabel;
@property (nonatomic,strong) UIView *buttonContainer;
@property (nonatomic,strong) NSMutableArray *buttons;
@property (nonatomic,assign) NSInteger cancelIndex;

@property (nonatomic,copy) PPSAlertViewSelectionBlock selectionHandler;
@end

@implementation PPSAlertView

+(PPSAlertView *)showAlertViewWithTitle:(NSString *)title message:(NSString *)message buttons:(NSArray *)buttons cancelButtonIndex:(NSInteger)cancelIndex selectionHandler:(PPSAlertViewSelectionBlock)selectionHandler
{
    PPSAlertView *p = [[PPSAlertView alloc] initWithButtons:buttons cancelButtonIndex:cancelIndex selectionHandler:selectionHandler];
    p.titleLabel.text = title;
    p.messageLabel.text = message;
    [[PPSAppDelegate appDelegate].masterViewController addOverlayView:p withMask:YES removeExisting:YES animated:YES];
    return p;
}

-(id)initWithButtons:(NSArray *)buttons cancelButtonIndex:(NSInteger)cancelIndex selectionHandler:(PPSAlertViewSelectionBlock)selectionHandler
{
    NIStylesheet *s = [[PPSAppDelegate appDelegate].stylesheetCache stylesheetWithPath:@"css/alertView.css"];
    self = [super initWithStylesheet: s withCssClass:nil andId:@"#alertView"];
    if (self) {
        self.selectionHandler = selectionHandler;
        self.stylesheet = s;
        self.cancelIndex = cancelIndex;
        [self buildSubviews:@[
         self.titleLabel = [UILabel new], @"#title",
         self.messageLabel = [UILabel new], @"#message",
         self.buttonContainer = [UIView new], @"#buttons"
         ] inDOM:self.dom];
        self.buttons = [NSMutableArray new];
        for (int i = 0; i < buttons.count; i++) {
            id button = [buttons objectAtIndex:i];
            if ([button isKindOfClass:[NSString class]]) {
                UIButton *newbutton = [UIButton buttonWithType:UIButtonTypeCustom];
                [newbutton setTitle: (NSString*)button forState:UIControlStateNormal];
                [self.buttons addObject:newbutton];
                [self.buttonContainer addSubview:newbutton];
                [self.dom registerView:newbutton];
                [newbutton addTarget:self action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
            } else if ([button isKindOfClass:[NSDictionary class]] || [button isKindOfClass:[NSArray class]]) {
                NSArray *specs = [button isKindOfClass:[NSDictionary class]] ? @[button]:button;
                UIButton* newButton = [[self.buttonContainer buildSubviews:specs inDOM:self.dom] objectAtIndex:0];
                [self.buttons addObject:newButton];
                if (selectionHandler) {
                    [newButton addTarget:self action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
                }
            } else if ([button isKindOfClass:[UIButton class]]) {
                [self.buttons addObject:button];
                [self.buttonContainer addSubview:button];
                if (selectionHandler) {
                    [(id)button addTarget:self action:@selector(buttonSelected:) forControlEvents:UIControlEventTouchUpInside];
                }
            }
        }
        if (cancelIndex >= 0 && cancelIndex < self.buttons.count) {
            [self.dom addCssClass:@".cancel" toView: [self.buttons objectAtIndex:cancelIndex]];
        }
    }
    return self;
}

-(void)dismiss:(BOOL)animated
{
    if (self.superview) {
        [[PPSAppDelegate appDelegate].masterViewController removeOverlayView:animated];
    }
}

-(void)buttonSelected: (UIButton*) sender
{
    if (self.selectionHandler) {
        self.selectionHandler(self, sender, [self.buttons indexOfObject:sender]);
    } else if ([self.buttons indexOfObject:sender] == self.cancelIndex) {
        // A simple alert with no handler - user presses the cancel button, dismiss it.
        // This still allows you to pass buttons with selectors into us.
        [self dismiss:YES];
    }
}

-(void)layoutSubviews
{
    CGFloat maxHeight = 0;
    for (UIView *button in self.buttonContainer.subviews) {
        maxHeight = MAX(maxHeight, button.frameMaxY);
    }
    self.buttonContainer.frameHeight = maxHeight;
    
    [super layoutSubviews];
    
    // CSS can't do it all unfortunately. So we need to check the message label size and sort it out in the context of the view
    NICSSRuleset *vars = [self.stylesheet rulesetForClassName:@"#variables"];
    NSArray *vPad = [vars cssRuleForKey:@"-vpadding"];
    CGFloat padding = 20;
    if (vPad && [vPad count] > 0) {
        padding = [[vPad objectAtIndex:0] floatValue];
    }
    
    CGSize minMessageSize = [self.messageLabel.text sizeWithFont:self.messageLabel.font constrainedToSize:CGSizeMake(self.messageLabel.frameWidth, MAXFLOAT)];
    self.messageLabel.frameHeight = minMessageSize.height;
    [self.dom refresh];
    
    __block CGFloat max = 0;
    [self.subviews enumerateObjectsUsingBlock:^(UIView *sub, NSUInteger idx, BOOL *stop) {
        max = MAX(max, sub.frameMaxY);
    }];
    self.frameHeight = MAX(self.frameHeight,max + padding);
    [self.dom refresh];
}

@end
