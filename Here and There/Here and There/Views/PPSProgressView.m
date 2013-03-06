//
//  PPSProgressView.m
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSProgressView.h"
#import "UIView+NIStyleable.h"
#import "PPSAppDelegate.h"
#import "NIStylesheet.h"
#import "NICSSRuleset.h"
#import "NIAttributedLabel.h"

@interface PPSProgressView () <
    NIAttributedLabelDelegate
>
@property (nonatomic,strong) NIStylesheet *stylesheet;
@property (nonatomic,strong) UILabel *titleText;
@property (nonatomic,strong) UILabel *messageText;
@property (nonatomic,strong) UIActivityIndicatorView *spinner;
@property (nonatomic,strong) NIAttributedLabel *cancel;
@property (nonatomic,copy) void (^cancelHandler)(PPSProgressView *);
@end

@implementation PPSProgressView

+(PPSProgressView *)progressViewWithTitle:(NSString *)title andMessage:(NSString *)message withCancelHandler:(void (^)(PPSProgressView *))cancelHandler
{
    PPSProgressView *p = [[PPSProgressView alloc] initWithCancel:cancelHandler];
    p.titleText.text = title;
    p.messageText.text = message;
    [[PPSAppDelegate appDelegate].masterViewController addOverlayView:p withMask:YES removeExisting:YES animated:YES];
    [p.spinner startAnimating];
    return p;
}

-(id)initWithCancel: (void (^)(PPSProgressView *))cancelHandler
{
    NIStylesheet *s = [[PPSAppDelegate appDelegate].stylesheetCache stylesheetWithPath:@"css/progressView.css"];
    self = [super initWithStylesheet: s withCssClass:nil andId:@"#progressView"];
    if (self) {
        self.stylesheet = s;
        [self buildSubviews:@[
         self.titleText = [UILabel new], @"#title",
         self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge], @"#spinner",
         self.messageText = [UILabel new], @"#message"
         ] inDOM:self.dom];
        if (cancelHandler) {
            self.cancelHandler = cancelHandler;
            [self buildSubviews:@[self.cancel = [NIAttributedLabel new],@"#cancel",[UIColor clearColor]] inDOM:self.dom];
            self.cancel.delegate = self;
            self.cancel.text = @"Cancel";
            self.cancel.linksHaveUnderlines = YES;
            [self.cancel addLink:[NSURL URLWithString:@"http://cancel.com/"] range:NSMakeRange(0, self.cancel.text.length)];
            self.cancel.linkColor = self.cancel.textColor;
        }
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
 
    // CSS can't do it all unfortunately. So we need to check the message label size and sort it out in the context of the view
    NICSSRuleset *vars = [self.stylesheet rulesetForClassName:@"#variables"];
    NSArray *vPad = [vars cssRuleForKey:@"-vpadding"];
    CGFloat padding = 20;
    if (vPad && [vPad count] > 0) {
        padding = [[vPad objectAtIndex:0] floatValue];
    }
    
    CGSize minMessageSize = [self.messageText.text sizeWithFont:self.messageText.font constrainedToSize:CGSizeMake(self.messageText.frameWidth, MAXFLOAT)];
    self.messageText.frameHeight = minMessageSize.height;
    
    __block CGFloat max = 0;
    [self.subviews enumerateObjectsUsingBlock:^(UIView *sub, NSUInteger idx, BOOL *stop) {
        max = MAX(max, sub.frameMaxY);
    }];
    self.frameHeight = MAX(self.frameHeight,max + padding);
    if (self.messageText.frameMaxY < self.frameHeight - (2*padding) - [self.cancel frameHeight]) {
        self.messageText.frameHeight = self.frameHeight - (2*padding) - [self.cancel frameHeight] - self.messageText.frameMinY;
    }
}

-(void)attributedLabel:(NIAttributedLabel *)attributedLabel didSelectTextCheckingResult:(NSTextCheckingResult *)result atPoint:(CGPoint)point
{
    self.cancelHandler(self);
}

-(void)dismiss:(BOOL)animated
{
    if (self.superview) {
        [[PPSAppDelegate appDelegate].masterViewController removeOverlayView:animated];
    }
}

@end
