//
//  PPSStyledView.h
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIDOM.h"

@interface PPSStyledView : UIView
@property (nonatomic,strong) NIDOM *dom;

-(id)initWithStylesheet: (NIStylesheet*) stylesheet withCssClass: (NSString*) cssClass andId: (NSString*) viewId;
-(id)initWithJsonResource: (NSString*) resourcePath andStylesheet: (NIStylesheet*) stylesheet withCssClass: (NSString*) cssClass andId: (NSString*) viewId withDOMTarget: (id) target;

-(void)sizeViewToFitContents: (UIView*) view;
@end
