//
//  PPSAlertView.h
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSStyledView.h"

@class PPSAlertView;

typedef void (^PPSAlertViewSelectionBlock)(PPSAlertView* alertView, UIButton *button, NSInteger index);

@interface PPSAlertView : PPSStyledView
+(PPSAlertView*)showAlertViewWithTitle: (NSString*) title
                           message: (NSString*) message
                           buttons: (NSArray*) buttons
                 cancelButtonIndex: (NSInteger) cancelIndex
                  selectionHandler: (PPSAlertViewSelectionBlock) selectionHandler;

-(id)initWithButtons: (NSArray*) buttons
   cancelButtonIndex: (NSInteger) cancelIndex
    selectionHandler: (PPSAlertViewSelectionBlock) selectionHandler;

-(void)dismiss: (BOOL) animated;
@end
