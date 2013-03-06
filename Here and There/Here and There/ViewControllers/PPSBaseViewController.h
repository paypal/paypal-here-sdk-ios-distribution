//
//  PPSBaseViewController.h
//  Here and There
//
//  Created by Metral, Max on 2/21/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NIDOM.h"
#import "UIView+NIStyleable.h"

@interface PPSBaseViewController : UIViewController
@property (nonatomic,strong) NIDOM *dom;

/**
 * The id of the view controller for CSS purposes - the default is to string ViewController off the end
 */
-(NSString*)viewControllerName;

/**
 * The name of the stylesheet specific to this view controller
 */
-(NSString*)stylesheetName;

/**
 * Setup the DOM object based on the global stylesheet and any custom
 * stylesheet for this view controller.
 */
-(void)setupDOM: (NIStylesheet*) globalStyles;

/**
 * Global styles used across the application
 */
+(NIStylesheet*) globalStyles;
@end
