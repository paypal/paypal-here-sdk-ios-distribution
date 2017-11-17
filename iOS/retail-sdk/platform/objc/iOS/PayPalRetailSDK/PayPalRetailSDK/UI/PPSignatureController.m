//
//  PPSignatureController.m
//  PayPalRetailSDK
//
//  Created by Metral, Max on 4/26/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PayPalRetailSDK+Private.h"
#import "PPSignatureController.h"
#import "PPSignatureView.h"
#import "PayPalRetailSDKStyles.h"
#import "PlatformView+PPAutoLayout.h"

@interface PPSignatureController () <
    PPSignatureViewDelegate
>
@property (nonatomic, strong) PPSignatureView *signatureView;

@property (nonatomic, strong) JSValue *options;
@property (nonatomic, strong) JSValue *callback;

@property (nonatomic, strong) UIView *divider;
@property (nonatomic, strong) UILabel *footerLabel;
@property (nonatomic, strong) UILabel *signHereLabel;
@property (nonatomic, strong) UIButton *clearButton;
@property (nonatomic, strong) UINavigationBar *topBar;
@property (nonatomic, strong) UIBarButtonItem *doneButton;

@property (nonatomic, strong) UIView *signatureViewContainer;
@property (nonatomic, strong) UIButton *ipadDoneButton;
@end

@implementation PPSignatureController
+(PPSignatureController *)signatureView:(JSValue *)options withCallback:(JSValue *)callback {
    PPSignatureController *controller = [[PPSignatureController alloc] init];
    controller.options = options;
    controller.callback = callback;
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:navController animated:YES completion:nil];
    return controller;
}

- (instancetype)init {
    if (self = [super init]) {
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange) name:UIDeviceOrientationDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)loadView {
    [super loadView];

    self.view.backgroundColor = [PayPalRetailSDKStyles viewBackgroundColor];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        //we switch the x and y dimensions
        self.view.frame = CGRectMake(self.view.frame.origin.x, self.view.frame.origin.y, self.view.frame.size.height, self.view.frame.size.width);
        CGAffineTransform ninetyDegrees = CGAffineTransformMakeRotation(M_PI_2);
        self.view.transform = ninetyDegrees;
    }

    self.footerLabel = [UILabel new];
    self.footerLabel.text = self.options[@"footer"].toString;
    [self.footerLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.footerLabel setTextAlignment:NSTextAlignmentCenter];
    [self.footerLabel setTextColor:[PayPalRetailSDKStyles secondaryTextColor]];
    [self.footerLabel setFont:[PayPalRetailSDKStyles smallFont]];
    [self.footerLabel sizeToFit];
    [self.view addSubview:self.footerLabel];

    self.divider = [UIView new];
    [self.divider setBackgroundColor:UIColorFromRGB(0xebf0f5)];
    [self.divider setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.signatureView = [PPSignatureView new];
    self.signatureView.clipsToBounds = YES;
    [self.signatureView setDelegate:self];
    [self.signatureView setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.clearButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.clearButton setImage:[PayPalRetailSDK sdkImageNamed:@"sdk_clear_signature_darkgrey"] forState:UIControlStateNormal];
    [self.clearButton setImage:[PayPalRetailSDK sdkImageNamed:@"sdk_clear_signature_lightblue"] forState:UIControlStateHighlighted];
    [self.clearButton addTarget:self action:@selector(clearButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.clearButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.clearButton.accessibilityIdentifier = @"Clear Signature Button";
    self.clearButton.enabled = NO;

    self.signHereLabel = [UILabel new];
    self.signHereLabel.text = self.options[@"signHere"].toString;
    [self.signHereLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.signHereLabel setTextColor:[PayPalRetailSDKStyles secondaryTextColor]];
    [self.signHereLabel setFont:[PayPalRetailSDKStyles largeFont]];
    [self.signHereLabel sizeToFit];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [self loadiPadView];
    } else {
        [self loadiPhoneView];
    }

    [self.view setNeedsUpdateConstraints];
}

- (void)loadiPhoneView {
    [self.navigationController setNavigationBarHidden:YES];

    self.topBar = [UINavigationBar new];
    [self.topBar setTranslatesAutoresizingMaskIntoConstraints:NO];
    UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:self.options[@"title"].toString];
    JSValue *cancel = self.options[@"cancel"];
    if (!cancel.isUndefined && !cancel.isNull) {
        [navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:cancel.toString
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self action:@selector(cancelButtonSelected)]];
    }
    self.doneButton = [[UIBarButtonItem alloc] initWithTitle:self.options[@"done"].toString
                                                       style:UIBarButtonItemStylePlain
                                                      target:self action:@selector(doneButtonPressed)];
    [navigationItem setRightBarButtonItem:self.doneButton];
    self.topBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    [self.topBar setItems:@[navigationItem]];
    self.topBar.opaque = YES;
    self.topBar.translucent = NO;
    [self.view addSubview:self.topBar];
    self.doneButton.enabled = NO;

    [self.view addSubview:self.signatureView];
    [self.view addSubview:self.clearButton];
    [self.view addSubview:self.signHereLabel];
    [self.view addSubview:self.divider];
}

- (void)loadiPadView {
    self.navigationItem.title = self.options[@"title"].toString;
    JSValue *cancel = self.options[@"cancel"];
    if (!cancel.isUndefined && !cancel.isNull) {
        [self.navigationItem setLeftBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:self.options[@"cancel"].toString style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonSelected)]];
        self.navigationItem.leftBarButtonItem.tintColor = [UIColor whiteColor];
    } else {
        [self.navigationItem setHidesBackButton:YES];
    }
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor]};
    self.navigationController.navigationBar.opaque = YES;
    self.navigationController.navigationBar.translucent = NO;

    self.clearButton.adjustsImageWhenHighlighted = NO;

    self.ipadDoneButton = [self button];
    [self.ipadDoneButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.ipadDoneButton setTitle:self.options[@"done"].toString forState:UIControlStateNormal];
    [self.ipadDoneButton setBackgroundColor:[PayPalRetailSDKStyles primaryButtonColor]];
    [self.ipadDoneButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.ipadDoneButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    // TODO this was "bold label2"
    [self.ipadDoneButton.titleLabel setFont:[PayPalRetailSDKStyles font]];
    // TODO why are we setting this twice?
    [self.ipadDoneButton setBackgroundColor:[PayPalRetailSDKStyles secondaryButtonColor]];
    [self.ipadDoneButton setEnabled:NO];
    [self.ipadDoneButton setClipsToBounds:YES];
    [self.view addSubview:self.ipadDoneButton];

    [self.signHereLabel setTextColor:UIColorFromRGB(0x97aabd)];
    [self.footerLabel setFont:[PayPalRetailSDKStyles smallFont]];

    // TODO : Chathura : PPSignatureView cannot capture the events ones it is added as a subview to another view which is a subview of the super most view. This
     //has to be addressed later.
     
    /*self.signatureViewContainer = [UIView new];
    [self.signatureViewContainer setBackgroundColor:UIColorFromRGB(0xebf0f5)];
    self.signatureViewContainer.layer.cornerRadius = 7.5;
    self.signatureViewContainer.layer.borderColor = [UIColorFromRGB(0xc5d1df) CGColor];
    self.signatureViewContainer.layer.borderWidth = 1.0f;
    self.signatureViewContainer.clipsToBounds = YES;
    [self.signatureViewContainer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.signatureViewContainer addSubview:self.signatureView];
    [self.signatureViewContainer addSubview:self.clearButton];
    [self.signatureViewContainer addSubview:self.signHereLabel];
    
    [self.view addSubview:self.signatureViewContainer];*/
    
    [self.view addSubview:self.signatureView];
    [self.view addSubview:self.clearButton];
    [self.view addSubview:self.signHereLabel];
}

static NSDictionary *bindings = nil;

- (void)updateViewConstraints {

    if ([[UIDevice currentDevice] userInterfaceIdiom] != UIUserInterfaceIdiomPad) {
        NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.topBar
                                                                      attribute:NSLayoutAttributeHeight
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:nil
                                                                      attribute:0
                                                                     multiplier:0
                                                                       constant:32];
        [self.topBar addConstraint:constraint];
        [self.topBar pinInSuperviewToEdges:PPViewEdgesHorizontal | PPViewEdgeTop withInset:0];
        
        [self.signatureView pinInSuperviewToEdges:PPViewEdgesHorizontal | PPViewEdgeBottom withInset:0];
        [self.signatureView pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.topBar inset:0];
        [self.clearButton pinInSuperviewToEdges:PPViewEdgeLeft withInset:10];
        [self.clearButton pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.topBar inset:10];
        [self.footerLabel pinInSuperviewToEdges:PPViewEdgeBottom withInset:10];
        [self.divider constrainToHeight:1];
        [self.divider pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:10];
        [self.divider pinEdge:NSLayoutAttributeBottom toEdge:NSLayoutAttributeTop ofView:self.footerLabel inset:-10];
    } else {
        
        [self.signatureView pinInSuperviewToEdges:PPViewEdgesHorizontal | PPViewEdgeTop withInset:0];
        [self.signatureView pinInSuperviewToEdges:PPViewEdgeAll withInset:80];
        [self.clearButton pinInSuperviewToEdges:PPViewEdgeTopRight withInset:10];
        [self.footerLabel pinInSuperviewToEdges:PPViewEdgeTop withInset:10];
        [self.ipadDoneButton pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.view inset:0];
        [self.ipadDoneButton constrainToHeight:56];
        [self.ipadDoneButton constrainToWidth:224];
        [self.ipadDoneButton pinInSuperviewToEdges:PPViewEdgeBottom withInset:40];
        [self.ipadDoneButton.layer setCornerRadius:8];
        [self.ipadDoneButton centerInSuperviewOnAxis:NSLayoutAttributeCenterX];

    }

    [self.signHereLabel centerInSuperview];
    [self.footerLabel pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:10];
    [super updateViewConstraints];
}

- (void)deviceOrientationDidChange {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
        UIInterfaceOrientation interfaceOrientation = [self interfaceOrientation];
        CGFloat transformSize = 0.0;
        NSInteger factor = 1;
        if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
            factor = -1;
        }
        if (deviceOrientation == UIDeviceOrientationLandscapeLeft) {
            transformSize = M_PI_2;
            self.view.transform = CGAffineTransformMakeRotation(factor*transformSize);
        }
        if (deviceOrientation == UIDeviceOrientationLandscapeRight) {
            transformSize = -M_PI_2;
            self.view.transform = CGAffineTransformMakeRotation(factor*transformSize);
        }
    }
}

-(void)dismiss {
    [self dismissViewControllerAnimated:YES completion:nil];
    self.callback = nil;
    self.options = nil;
}

#pragma mark -
#pragma mark Actions

- (void)doneButtonPressed {
    UIImage *printable = [self.signatureView printableImage];
    [self.callback callWithArguments:@[[NSNull null],[UIImageJPEGRepresentation(printable, 0.5) base64EncodedStringWithOptions:0]]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelButtonSelected {
    [self.callback callWithArguments:@[[NSNull null], [NSNull null], @YES]];
}

- (void)clearButtonPressed {
    self.signHereLabel.hidden = NO;
    self.doneButton.enabled = NO;
    self.clearButton.enabled = NO;
    self.ipadDoneButton.enabled = NO;
    [self.ipadDoneButton setBackgroundColor:UIColorFromRGB(0xc5d1df)];

    [self.signatureView clearSignaturePad];
}

#pragma mark -
#pragma mark PPHSignatureViewDelegate


- (void)signatureTouchesBegan {
    self.signHereLabel.hidden = YES;
    self.doneButton.enabled = YES;
    self.clearButton.enabled = YES;
    self.ipadDoneButton.enabled = YES;
    [self.ipadDoneButton setBackgroundColor:[PayPalRetailSDKStyles primaryButtonColor]];
}

- (void)signatureUpdated:(BOOL)isEmpty {

}

#pragma mark -

-(UIButton*)button {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.layer.cornerRadius = 2;
    button.titleLabel.textColor = [UIColor whiteColor];
    button.titleLabel.font = [PayPalRetailSDKStyles font];
    button.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    return button;
}
@end
