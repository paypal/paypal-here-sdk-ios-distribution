//
//  PPHReceiptOptionsView.m
//  PPHCore
//
//  Created by Beiser, Chris on 2/19/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import "PPReceiptOptionsController.h"
#import "PayPalRetailSDK+Private.h"
#import "PayPalRetailSDKStyles.h"
#import "PlatformView+PPAutoLayout.h"

#import "PPReceiptSMSEntryController.h"
#import "PPReceiptEmailEntryController.h"
#import "PayPalRetailSDK.h";

//#import "PPHReceiptOption.h"
//#import "UIView+PPHSDKAutolayout.h"
//#import "PPHSDKSendEmailReceiptViewController.h"
//#import "PPHSDKSendTextReceiptViewController.h"
//#import "UIImage+PPHSDKExtensions.h"
//#import "PPHSDKStyleSheet.h"
//#import "PPHTransactionRecord-Internal.h"
//#import "PPHTokenizedCustomerInformation.h"
//#import "PPHSDKPhoneFormatter.h"
//#import "PPHInvoice+Private.h"
//#import "PPHSDKAlertView.h"
//#import "PayPalHereSDKSingleton-Internal.h"
//#import "PPHTransactionManager.h"
//#import "PPEnvironment.h"
//
//#ifdef DEBUG
//#import "Bond.h"
//#import "PPHBondReaderDelegate.h"
//#endif



////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPReceiptOptionsController ()

@property (nonatomic, strong) PPRetailInvoice *invoice;
@property (nonatomic, strong) PPRetailError *error;
@property (nonatomic, strong) PPRetailReceiptViewContent *allContent;
@property (nonatomic, strong) PPRetailReceiptOptionsViewContent *content;
@property (nonatomic, copy) PPReceiptDestinationCallback callback;
@property (nonatomic, strong) NSString *prefilledEmail;
@property (nonatomic, strong) NSString *prefilledPhone;

// UI
@property (nonatomic, strong) UIImageView *navStatusImageView;
@property (nonatomic, strong) NSMutableArray *receiptOptionViews;
@property (nonatomic, strong) UILabel *amountLabel;
@property (nonatomic, strong) UILabel  *receiptStatusLabel;
@property (nonatomic, strong) UILabel *receiptStatusCaption;
@property (nonatomic, strong) UIButton *emailButton;
@property (nonatomic, strong) UIButton *textButton;
@property (nonatomic, strong) UIButton *noReceiptAndDoneButton;
@property (nonatomic, strong) UIButton *emailComposeButton;
@property (nonatomic, strong) UIButton *textComposeButton;
@property (nonatomic, strong) UITextView *legalDisclaimerTextView;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PPReceiptOptionsController

+ (void)presentReceiptOptionsControllerWithInvoice:(PPRetailInvoice *)invoice
                                             error:(PPRetailError *)error
                                           content:(PPRetailReceiptViewContent *)content
                                          callback:(PPReceiptDestinationCallback)callback {
    
    PPReceiptOptionsController *vc = [[PPReceiptOptionsController alloc] init];
    vc.invoice = invoice;
    vc.error = error;
    vc.allContent = content;
    vc.content = content.receiptOptionsViewContent;
    vc.callback = callback;
    vc.prefilledEmail = vc.content.maskedEmail;
    vc.prefilledPhone = vc.content.maskedPhone;

    UIViewController *appViewController = [PayPalRetailSDK getCurrentNavigationController] ?:
        [UIApplication sharedApplication].keyWindow.rootViewController;
    BOOL isPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
    BOOL appVcIsRootVc = [UIApplication sharedApplication].keyWindow.rootViewController == appViewController;
    
    // TODO Identify the exact cause of refund receipt issue on iPad and base the decision on that
    if(isPad && !appVcIsRootVc && [appViewController isKindOfClass:[UINavigationController class]] ) {
        UINavigationController *topNavigationController = (UINavigationController *) appViewController;
        [topNavigationController pushViewController:vc animated:YES];
    } else {
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
        [appViewController presentViewController:navController animated:YES completion:nil];
    }

}

#pragma mark -
#pragma mark UIViewController
- (void)updateViewConstraints {
    [super updateViewConstraints];

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.receiptStatusLabel pinInSuperviewToEdges:PPViewEdgeTop withInset:88];
    } else {
        [self.receiptStatusLabel pinInSuperviewToEdges:PPViewEdgeTop withInset:46];
    }
    [self.receiptStatusLabel setTextAlignment:NSTextAlignmentCenter];
    [self.receiptStatusLabel pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:0];
    
    [self.receiptStatusCaption pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.receiptStatusLabel inset:17];
    [self.receiptStatusCaption setTextAlignment:NSTextAlignmentCenter];
    [self.receiptStatusCaption pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:0];

    UIView *previousView;
    for (UIView *view in self.receiptOptionViews) {
        [view constrainToHeight:58];
        
        if (view == self.legalDisclaimerTextView) {
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                [view constrainToWidth:480];
            } else {
                [view pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:(self.view.frame.size.width/20)];
            }
            
            [view centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
            [view pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:previousView inset:2];
        } else {
            [view pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:0];
            
            if (view == self.emailButton) {
                [view pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.receiptStatusCaption inset:46];
            } else {
                [view pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:previousView inset:2];
            }
            [self bottomLineViewForView:view];
        }
        previousView = view;
    }
    
    [self.emailComposeButton pinAttribute:NSLayoutAttributeTop toSameOfView:self.emailButton];
    [self.emailComposeButton pinAttribute:NSLayoutAttributeBottom toSameOfView:self.emailButton];
    [self.emailComposeButton pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:self.view inset:0];
    [self.emailComposeButton constrainToWidth:58];
    
    [self.textComposeButton pinAttribute:NSLayoutAttributeTop toSameOfView:self.textButton];
    [self.textComposeButton pinAttribute:NSLayoutAttributeBottom toSameOfView:self.textButton];
    [self.textComposeButton pinEdge:NSLayoutAttributeRight toEdge:NSLayoutAttributeRight ofView:self.view inset:0];
    [self.textComposeButton constrainToWidth:58];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    BOOL iPad = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
    
    self.view.backgroundColor = [PayPalRetailSDKStyles viewBackgroundColor];
    self.navigationItem.hidesBackButton = YES;

    self.receiptOptionViews = [NSMutableArray new];
    
    self.emailButton = [UIButton new];
    self.emailButton.accessibilityIdentifier = @"Email";
    [self.emailButton setTitleColor:[PayPalRetailSDKStyles primaryButtonColor] forState:UIControlStateNormal];
    if (self.prefilledEmail) {
        [self.emailButton setTitle:self.prefilledEmail forState:UIControlStateNormal];
        [self.emailButton addTarget:self action:@selector(emailPressedWhilePrefilled) forControlEvents:UIControlEventTouchUpInside];
        self.emailComposeButton = [UIButton new];
        [self.emailComposeButton setImage:[PayPalRetailSDK sdkImageNamed:@"ic_edit_receipt"] forState:UIControlStateNormal];
        [self.emailComposeButton setImage:[PayPalRetailSDK sdkImageNamed:@"ic_edit_receipt_pressed"] forState:UIControlStateHighlighted];
        [self.emailComposeButton addTarget:self action:@selector(emailButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.emailComposeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:self.emailComposeButton];
    } else {
        [self.emailButton setTitle:self.content.emailButtonTitle forState:UIControlStateNormal];
        [self.emailButton addTarget:self action:@selector(emailButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.emailButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.textButton = [UIButton new];
    self.textButton.accessibilityIdentifier = @"Text";
    [self.textButton setTitleColor:[PayPalRetailSDKStyles primaryButtonColor] forState:UIControlStateNormal];
    if (self.prefilledPhone) {
        [self.textButton setTitle:self.prefilledPhone forState:UIControlStateNormal];
        [self.textButton addTarget:self action:@selector(textPressedWhilePrefilled) forControlEvents:UIControlEventTouchUpInside];
        self.textComposeButton = [UIButton new];
        [self.textComposeButton setImage:[PayPalRetailSDK sdkImageNamed:@"ic_edit_receipt"] forState:UIControlStateNormal];
        [self.textComposeButton setImage:[PayPalRetailSDK sdkImageNamed:@"ic_edit_receipt_pressed"] forState:UIControlStateHighlighted];
        [self.textComposeButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.textComposeButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.view addSubview:self.textComposeButton];
    } else {
        [self.textButton setTitle:self.content.smsButtonTitle forState:UIControlStateNormal];
        [self.textButton addTarget:self action:@selector(textButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    [self.textButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.receiptOptionViews addObject:self.emailButton];
    [self.receiptOptionViews addObject:self.textButton];

    self.receiptStatusLabel = [[UILabel alloc] init];
    self.receiptStatusLabel.text = self.content.message;//[self receiptStatusText];
    [self.receiptStatusLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.receiptStatusLabel setFont:[PayPalRetailSDKStyles fontWithSize:iPad?64.0f:32.0f]];
    [self.receiptStatusLabel setTextColor:[PayPalRetailSDKStyles primaryTextColor]];
    
    self.receiptStatusCaption = [[UILabel alloc] init];
    self.receiptStatusCaption.text = @"Would you like to get a receipt?";//((self.receiptContext.record.paymentMethod == ePPHPaymentMethodPaypal) ? SDK_LOCALIZED_STRING(@"PPH_CheckinReceiptQuestion", nil) : SDK_LOCALIZED_STRING(@"PPH_ReceiptQuestion", nil));
    self.receiptStatusCaption.numberOfLines = 0;
    
    [self.receiptStatusCaption setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.receiptStatusCaption setFont:[PayPalRetailSDKStyles fontWithSize:iPad?30.0f:15.0f]];
    [self.receiptStatusCaption setTextColor:[PayPalRetailSDKStyles primaryTextColor]];
    
    self.noReceiptAndDoneButton = [UIButton new];
    [self.noReceiptAndDoneButton setTitleColor:[PayPalRetailSDKStyles primaryButtonColor] forState:UIControlStateNormal];
    [self.noReceiptAndDoneButton setTitle:self.content.noThanksButtonTitle forState:UIControlStateNormal];
    [self.noReceiptAndDoneButton addTarget:self action:@selector(doneButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [self.noReceiptAndDoneButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.legalDisclaimerTextView = [UITextView new];
    [self.legalDisclaimerTextView setText:self.content.disclaimer];
    [self.legalDisclaimerTextView setEditable:NO];
    [self.legalDisclaimerTextView setTextAlignment:NSTextAlignmentCenter];
    [self.legalDisclaimerTextView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.receiptOptionViews addObject:self.emailButton];
    [self.receiptOptionViews addObject:self.textButton];
    [self.receiptOptionViews addObjectsFromArray:[self generateOptionButtonsFromOptions:self.content.additionalReceiptOptions]];
    [self.receiptOptionViews addObject:self.noReceiptAndDoneButton];
    [self.receiptOptionViews addObject:self.legalDisclaimerTextView];
    
    [self.view addSubview:self.receiptStatusLabel];
    [self.view addSubview:self.receiptStatusCaption];
    for (UIView *view in self.receiptOptionViews) {
        [self.view addSubview:view];
    }
    if (self.textComposeButton) {
        [self.view bringSubviewToFront:self.textComposeButton];
    }
    if (self.emailComposeButton) {
        [self.view bringSubviewToFront:self.emailComposeButton];
    }
    
    UIImageView *navStatusImageView = [[UIImageView alloc] initWithImage:[PayPalRetailSDK sdkImageNamed:self.content.titleIconFilename]];
    
    
    UILabel *navTotalLabel = [[UILabel alloc] initWithFrame:CGRectMake(navStatusImageView.frame.size.width + 10, 6, 0, 0)];
    [navTotalLabel setTextColor:[UIColor whiteColor]];
    navTotalLabel.text = self.content.title;
    [navTotalLabel sizeToFit];
    
    UIView *navView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, navTotalLabel.frame.size.width + navStatusImageView.frame.size.width + 10, self.navigationController.navigationBar.frame.size.height)];
    
    CGRect navStatusImageViewFrame = CGRectMake(navStatusImageView.frame.origin.x,
                                                navView.frame.origin.y + navView.frame.size.height/2 - navStatusImageView.frame.size.height/2,
                                                navStatusImageView.frame.size.width,
                                                navStatusImageView.frame.size.height);
    
    [navStatusImageView setFrame:navStatusImageViewFrame];
    
    CGRect navTotalLabelFrame = CGRectMake(navTotalLabel.frame.origin.x,
                                                navView.frame.origin.y + navView.frame.size.height/2 - navTotalLabel.frame.size.height/2,
                                                navTotalLabel.frame.size.width,
                                                navTotalLabel.frame.size.height);
    [navTotalLabel setFrame:navTotalLabelFrame];

    
    [navView addSubview:navStatusImageView];
    [navView addSubview:navTotalLabel];
    [navView sizeToFit];
    
    self.navigationItem.titleView = navView;
    
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (UIView *)bottomLineViewForView:(UIView *)view {
    UIView *lineView = [UIView new];
    lineView.backgroundColor = UIColorFromRGB(0xebf0f5);
    [lineView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:lineView];
    
    [lineView constrainToHeight:1];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [lineView constrainToWidth:480];
    } else {
        [lineView pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:(self.view.frame.size.width/20)];
    }
    
    [lineView centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
    [lineView pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:view inset:0];
    
    return lineView;
}

- (NSArray *)generateOptionButtonsFromOptions:(NSArray *)options {
    NSMutableArray *optionButtons = [[NSMutableArray alloc] initWithCapacity:options.count];
    [options enumerateObjectsUsingBlock:^(NSString *optionName, NSUInteger idx, BOOL *stop) {
        UIButton *button = [UIButton new];
        [button setTag:idx];
        [button setTitle:optionName forState:UIControlStateNormal];
        [button addTarget:self action:@selector(optionButtonPressedWithSender:) forControlEvents:UIControlEventTouchUpInside];
        [button setTranslatesAutoresizingMaskIntoConstraints:NO];
        [button.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [optionButtons addObject:button];
    }];
    
    return optionButtons;
}

#pragma mark -
#pragma mark Actions
- (void)emailButtonPressed {
    PPReceiptEmailEntryController *vc = [[PPReceiptEmailEntryController alloc] initWithContent:self.allContent.receiptEmailEntryViewContent
                                                                                suggestedEmail:nil
                                                                                      callback:self.callback];
    
    [[self navigationController] pushViewController:vc
                                           animated:YES];
}

- (void)textButtonPressed {
    PPReceiptSMSEntryController *vc = [[PPReceiptSMSEntryController alloc] initWithContent:self.allContent.receiptSMSEntryViewContent
                                                                            suggestedPhone:nil
                                                                                  callback:self.callback];
    [[self navigationController] pushViewController:vc
                                           animated:YES];
}

- (void)optionButtonPressedWithSender:(UIButton *)sender {
    NSString *optionName = [self.content.additionalReceiptOptions objectAtIndex:[sender tag]];
    NSLog(@"%@", [NSString stringWithFormat:@"The selected option name %@, index %d", optionName, sender.tag]);
    [self invokeCallbackWithOptionName:optionName value:[NSNumber numberWithInteger:sender.tag]];
}


- (void)emailPressedWhilePrefilled {
    [self sendEmailOrSms:self.prefilledEmail];
}

- (void)textPressedWhilePrefilled {
    [self sendEmailOrSms:self.prefilledPhone];
}

- (void)doneButtonPressed {
    self.callback(nil, nil);
}

- (void)sendEmailOrSms:(NSString *)emailOrSms {
    [self invokeCallbackWithOptionName:@"emailOrSms" value:emailOrSms];
}

- (void)invokeCallbackWithOptionName:(NSString *)name value:(NSObject *)value {
    self.callback(nil, @{@"name": name, @"value":value});
}

#pragma mark -
#pragma mark textView delegate
- (BOOL)textView:(UITextView *)tv shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange {
    if (tv == self.legalDisclaimerTextView) {
        return YES;
    }
    return NO;
}

@end
