//
//  PPSCardReaderEventView.m
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSAppDelegate.h"
#import "PPSCardReaderEventView.h"

@interface PPSCardReaderEventView ()
@property (nonatomic,strong) UILabel *eventText;
@end

@implementation PPSCardReaderEventView

-(id)init
{
    self = [super initWithStylesheet: [[PPSAppDelegate appDelegate].stylesheetCache stylesheetWithPath:@"css/cardReaderEventView.css"] withCssClass:nil andId:@"#eventView"];
    if (self) {
        self.eventText = [[UILabel alloc] init];
        [self addSubview:self.eventText];
        [self.dom registerView:self.eventText];
    }
    return self;
}

@end
