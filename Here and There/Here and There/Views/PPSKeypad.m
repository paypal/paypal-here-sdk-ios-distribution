//
//  PPSKeypad.m
//  Here and There
//
//  Created by Metral, Max on 2/26/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSKeypad.h"
#import "UIView+NIStyleable.h"
#import "NIUserInterfaceString.h"
#import "NIInvocationMethods.h"

@interface PPSKeypad ()
@property (nonatomic,strong) UIButton* b1;
@property (nonatomic,strong) UIButton* b2;
@property (nonatomic,strong) UIButton* b3;
@property (nonatomic,strong) UIButton* b4;
@property (nonatomic,strong) UIButton* b5;
@property (nonatomic,strong) UIButton* b6;
@property (nonatomic,strong) UIButton* b7;
@property (nonatomic,strong) UIButton* b8;
@property (nonatomic,strong) UIButton* b9;
@property (nonatomic,strong) UIButton* b0;
@property (nonatomic,strong) UIButton* deleteKey;
@property (nonatomic,strong) UIButton* decimalKey;
@end

#define SELECTOR(x) NIInvocationWithInstanceTarget(self, @selector(x))

@implementation PPSKeypad

-(id)init {
    NIStylesheet *s = [[PPSAppDelegate appDelegate].stylesheetCache stylesheetWithPath:@"css/keypad.css"];
    self = [super initWithStylesheet: s withCssClass:nil andId:@"#keypad"];
    if (self) {
        [self buildSubviews:@[
         // First row
        [UIView class], @".row", @"#r1", @[
            self.b1 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b1", NILocalizedStringWithDefault(@"b1", @"1"), SELECTOR(keyPress:),
            self.b2 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b2", NILocalizedStringWithDefault(@"b2", @"2"), SELECTOR(keyPress:),
            self.b3 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b3", NILocalizedStringWithDefault(@"b3", @"3"), SELECTOR(keyPress:)
         ],
         // Second row
         [UIView class], @".row", @"#r2", @[
            self.b4 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b4", NILocalizedStringWithDefault(@"b4", @"4"), SELECTOR(keyPress:),
            self.b5 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b5", NILocalizedStringWithDefault(@"b5", @"5"), SELECTOR(keyPress:),
            self.b6 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b6", NILocalizedStringWithDefault(@"b6", @"6"), SELECTOR(keyPress:)
         ],
         // Third row
         [UIView class], @".row", @"#r3", @[
            self.b7 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b7", NILocalizedStringWithDefault(@"b7", @"1"), SELECTOR(keyPress:),
            self.b8 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b8", NILocalizedStringWithDefault(@"b8", @"2"), SELECTOR(keyPress:),
            self.b9 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b9", NILocalizedStringWithDefault(@"b9", @"3"), SELECTOR(keyPress:)
         ],
         // Fourth row
         [UIView class], @".row", @"#r4", @[
            self.decimalKey = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#bdot", NILocalizedStringWithDefault(@"bdot", @"."), SELECTOR(decimalPress:),
            self.b0 = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#b0", NILocalizedStringWithDefault(@"b2", @"0"), SELECTOR(keyPress:),
            self.deleteKey = [UIButton buttonWithType:UIButtonTypeCustom], @".btn", @"#bdel", NILocalizedStringWithDefault(@"b3", @"x"), SELECTOR(deletePress:)
         ]
         ] inDOM:self.dom];
    }
    return self;
}

-(void)keyPress: (UIButton*) sender
{
    [self.delegate insertText: [sender titleForState:UIControlStateNormal]];
}

-(void)decimalPress: (UIButton*) sender
{
    if ([self.delegate.text rangeOfString:@"."].location == NSNotFound) {
        [self.delegate insertText:@"."];
    }
}

-(void)deletePress: (UIButton*) sender
{
    [self.delegate deleteBackward];
}
@end
