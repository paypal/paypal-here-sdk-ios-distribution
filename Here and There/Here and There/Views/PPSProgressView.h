//
//  PPSProgressView.h
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSStyledView.h"

@interface PPSProgressView : PPSStyledView

+(PPSProgressView*)progressViewWithTitle: (NSString*) title andMessage: (NSString*) message withCancelHandler: (void(^)(PPSProgressView* progressView)) cancelHandler;

/**
 * Just calls up to PPSMasterViewController to remove the overlay
 */
-(void)dismiss: (BOOL)animated;

@end
