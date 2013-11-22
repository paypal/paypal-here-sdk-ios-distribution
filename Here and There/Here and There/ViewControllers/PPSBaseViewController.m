//
//  PPSBaseViewController.m
//  Here and There
//
//  Created by Metral, Max on 2/21/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import "PPSBaseViewController.h"
#import "PPSAppDelegate.h"
#import "NIStylesheet.h"

@interface PPSBaseViewController ()

@end

static NIStylesheet *globalStyles;

@implementation PPSBaseViewController

-(id)init
{
    self = [super init];
    if (self) {
        [self setupDOM: [PPSBaseViewController globalStyles]];
#ifdef DEBUG
        // Enable Chameleon in debug mode
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stylesheetDidChange)
                                                     name:NIStylesheetDidChangeNotification
                                                   object:globalStyles];
#endif
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    return self;
}

/**
 * Only use a specific style sheet if set
 */
-(NSString *)stylesheetName
{
    return nil;
}

/**
 * Default name is just the class name with ViewController stripped off.
 */
-(NSString *)viewControllerName
{
    NSString *vcn = NSStringFromClass([self class]);
    if ([vcn hasSuffix:@"ViewController"]) {
        vcn = [vcn substringToIndex:vcn.length - 14];
    }
    return vcn;
}

/**
 * The default implementation loads a custom stylesheet if set, or just global if not
 */
-(void)setupDOM:(NIStylesheet *)globalStyles
{
    NSString *mySheet = self.stylesheetName;
    if (mySheet) {
        mySheet = [NSString stringWithFormat:@"css/%@.css", mySheet];
        NIStylesheet *stylesheet = [[PPSAppDelegate appDelegate].stylesheetCache stylesheetWithPath:mySheet];
        _dom = [NIDOM domWithStylesheet: stylesheet andParentStyles:globalStyles];
        _dom.target = self;
#ifdef DEBUG
        // Enable Chameleon in debug mode
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(stylesheetDidChange)
                                                     name:NIStylesheetDidChangeNotification
                                                   object:stylesheet];
#endif
    } else {
        _dom = [NIDOM domWithStylesheet:globalStyles];
    }
}

-(void)loadView
{
    [super loadView];
    [_dom registerView:self.view withCSSClass:@"viewController" andId:self.viewControllerName];
}

#ifdef DEBUG
// Enable Chameleon CSS Updater when in debug mode
-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)stylesheetDidChange
{
    [self.dom refresh];
}
#endif

+(NIStylesheet *)globalStyles
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        globalStyles = [[PPSAppDelegate appDelegate].stylesheetCache stylesheetWithPath:@"css/global.css"];
    });
    return globalStyles;
}


@end
