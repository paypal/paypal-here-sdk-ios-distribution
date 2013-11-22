//
//  PPSMasterViewController.h
//  Here and There
//
//  Created by Metral, Max on 2/23/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PPSMasterViewController : UIViewController

@property (nonatomic,strong) UIViewController *mainController;

-(id)initWithWindow: (UIWindow*) window andViewController:(UIViewController *)controller;

/**
 * Add a view in front of everything else including the keyboard, optionally
 * blocking any other input
 */
-(BOOL)addOverlayView: (UIView*) view withMask: (BOOL) addInputMask removeExisting: (BOOL) removeExisting animated: (BOOL) animated;

/**
 * Remove any existing overlay view
 */
-(void)removeOverlayView: (BOOL) animated;
@end
