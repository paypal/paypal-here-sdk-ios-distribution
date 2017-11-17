//
//  PPBaseViewController.m
//  Pods
//
//  Created by Pavlinsky, Matthew on 4/5/16.
//
//

#import "PPBaseViewController.h"
#import "PayPalRetailSDKStyles.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PPBaseViewController

+ (void)initialize {
    if (self == [PPBaseViewController self]) {
        [self setupAppearance];
    }
}


+ (void)setupAppearance {
    
    NSDictionary *attributes = @{
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSBackgroundColorAttributeName : [UIColor clearColor]
                                 };
    [[UIBarButtonItem appearanceWhenContainedIn:[PPBaseViewController class], nil] setTitleTextAttributes:attributes forState:UIControlStateNormal];
    NSDictionary *attributesDisabled = @{
                                         NSForegroundColorAttributeName : UIColorFromRGB(0xebf0f5),
                                         NSBackgroundColorAttributeName : [UIColor clearColor]
                                         };
    [[UIBarButtonItem appearanceWhenContainedIn:[PPBaseViewController class], nil] setTitleTextAttributes:attributesDisabled forState:UIControlStateDisabled];
    
    [[UINavigationBar appearanceWhenContainedIn:[PPBaseViewController class], nil] setTitleTextAttributes:attributes];
    [[UINavigationBar appearanceWhenContainedIn:[PPBaseViewController class], nil] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearanceWhenContainedIn:[PPBaseViewController class], nil] setBarTintColor:[PayPalRetailSDKStyles primaryNavBarColor]];
    
    [[UIButton appearanceWhenContainedIn:[PPBaseViewController class], nil] setTitleColor:UIColorFromRGB(0x33c2ff) forState:UIControlStateNormal];
    
    //get a 1x1 UIImage of the pressed color of the button
    UIView *pressedColor = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [pressedColor setBackgroundColor:UIColorFromRGB(0xe9faff)];
    UIGraphicsBeginImageContext(CGSizeMake(1, 1));
    [pressedColor.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *buttonBackgroundImage = UIGraphicsGetImageFromCurrentImageContext();
    
    [[UIButton appearanceWhenContainedIn:[PPBaseViewController class], nil] setBackgroundImage:buttonBackgroundImage forState:UIControlStateHighlighted];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.navigationController.navigationBar.barTintColor = [PayPalRetailSDKStyles primaryNavBarColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationIsPortrait(interfaceOrientation);
    }
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return YES;
}


#ifdef __IPHONE_9_0
typedef UIInterfaceOrientationMask PPSupportedInterfaceOrientationsReturnType;
#else
typedef NSUInteger PPSupportedInterfaceOrientationsReturnType;
#endif


- (PPSupportedInterfaceOrientationsReturnType)supportedInterfaceOrientations {
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        return UIInterfaceOrientationMaskPortrait;
    }
    return UIInterfaceOrientationMaskLandscape;
}

@end
