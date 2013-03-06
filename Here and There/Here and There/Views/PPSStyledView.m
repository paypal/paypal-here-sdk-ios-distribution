//
//  PPSStyledView.m
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSStyledView.h"
#import "PPSBaseViewController.h"

@implementation PPSStyledView

-(id)initWithStylesheet:(NIStylesheet *)stylesheet withCssClass:(NSString *)cssClass andId:(NSString *)viewId
{
    if ((self = [super init])) {
        self.dom = [NIDOM domWithStylesheet:stylesheet andParentStyles:[PPSBaseViewController globalStyles]];
        [self.dom registerView:self withCSSClass:cssClass andId:viewId];
    }
    return self;
}

-(id)initWithJsonResource:(NSString *)resourcePath andStylesheet:(NIStylesheet *)stylesheet withCssClass:(NSString *)cssClass andId:(NSString *)viewId withDOMTarget:(id)target
{
    if ((self = [self initWithStylesheet:stylesheet withCssClass:cssClass andId:viewId])) {
        _dom.target = target;
        NSString *filePath = [[NSBundle mainBundle] pathForResource:resourcePath ofType:@"json" inDirectory:@"json"];
        NSArray *viewSpecs = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:filePath] options:0 error:nil];

        [self buildSubviews:viewSpecs inDOM:_dom];
    }
    return self;
}

-(void)didMoveToSuperview
{
    [super didMoveToSuperview];
    [self.dom refresh];
}

-(void)sizeViewToFitContents:(UIView *)view
{
    __block CGSize sz = CGSizeZero;
    [view.subviews enumerateObjectsUsingBlock:^(UIView *v, NSUInteger idx, BOOL *stop) {
        sz.height = MAX(sz.height, v.frameMaxY);
        sz.width = MAX(sz.width, v.frameMaxX);
    }];
    view.frameWidth = sz.width;
    view.frameHeight = sz.height;
}
@end
