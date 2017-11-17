//
//  PPReceiptEmailEntryController.m
//  PayPal Retail SDK
//
//  Created by Pavlinsky, Matthew on 4/8/16.
//  Copyright (c) 2016 PayPal. All rights reserved.
//

#import "PPReceiptEmailEntryController.h"
#import "PayPalRetailSDK+Private.h"
#import "PayPalRetailSDKStyles.h"
#import "PlatformView+PPAutoLayout.h"

////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPReceiptEmailEntryController ()<
UITextFieldDelegate
>
@property (nonatomic, strong) PPRetailReceiptEmailEntryViewContent *content;
@property (nonatomic, strong) NSString *suggestedEmail;
//@property (nonatomic, strong) PPHSDKAlertView *alert;
@property (nonatomic, strong) UITextField *emailField;
@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, strong) UILabel *legalDisclaimer;
@property (copy) PPReceiptDestinationCallback callback;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PPReceiptEmailEntryController

#pragma mark -
#pragma mark init
- (instancetype)initWithContent:(PPRetailReceiptEmailEntryViewContent *)content
                 suggestedEmail:(NSString *)suggestedEmail
                       callback:(PPReceiptDestinationCallback)callback {
    if (self = [super init]) {
        self.content = content;
        self.callback = callback;
    }
    return self;
}

#pragma mark -
#pragma mark UIViewController
- (void)loadView {
    [super loadView];
    self.title = self.content.title;

    self.emailField = [UITextField new];
    [self.emailField setPlaceholder:self.content.placeholder];
    self.emailField.text = self.suggestedEmail;
    [self.emailField setFont:[PayPalRetailSDKStyles boldFontWithSize:15.0f]];
    [self.emailField setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.emailField.delegate = self;
    self.emailField.keyboardType = UIKeyboardTypeEmailAddress;
    self.emailField.returnKeyType = UIReturnKeySend;
    self.emailField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.emailField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.emailField.backgroundColor = [UIColor whiteColor];
    self.emailField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;

    UIImageView *bubbleImage = [[UIImageView alloc] initWithImage:[PayPalRetailSDK sdkImageNamed:@"ic_email"]];
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleImage.frame.size.width * 1.50, bubbleImage.frame.size.height)];
    [leftView addSubview:bubbleImage];

    self.emailField.leftView = leftView;
    self.emailField.leftViewMode = UITextFieldViewModeAlways;
    
    self.legalDisclaimer = [UILabel new];
    [self.legalDisclaimer setText:self.content.disclaimer];
    [self.legalDisclaimer setFont:[PayPalRetailSDKStyles fontWithSize:15.0f]];
    [self.legalDisclaimer setTextColor:[PayPalRetailSDKStyles primaryTextColor]];
    [self.legalDisclaimer setNumberOfLines:0];
    [self.legalDisclaimer setLineBreakMode:NSLineBreakByWordWrapping];
    [self.legalDisclaimer setTextAlignment:NSTextAlignmentCenter];
    [self.legalDisclaimer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.legalDisclaimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.centerButton = [UIButton new];
        [self.centerButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.centerButton setTitle:self.content.sendButtonTitle forState:UIControlStateNormal];
        [self.view addSubview:self.centerButton];
        [self.centerButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.centerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.centerButton.titleLabel setFont:[PayPalRetailSDKStyles boldFontWithSize:21.0f]];
    } else {
        UIBarButtonItem *text = [[UIBarButtonItem alloc] initWithTitle:self.content.sendButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(sendPressed)];
        self.navigationItem.rightBarButtonItem = text;
    }

    [self.view addSubview:self.emailField];
    [self.emailField becomeFirstResponder];
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.emailField constrainToHeight: 64];
        [self.emailField constrainToWidth:480];
        [self.emailField centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
        [self.emailField pinInSuperviewToEdges:PPViewEdgeTop withInset:64];
        
        [self.centerButton centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
        [self.centerButton pinInSuperviewToEdges:PPViewEdgeBottom withInset:382];
        [self.centerButton constrainToHeight:54];
        [self.centerButton constrainToWidth:220];
        
        [self.legalDisclaimer pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.emailField inset:30];
        [self.legalDisclaimer pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:100];
        [self.legalDisclaimer sizeToFit];

    } else {
        [self.emailField pinInSuperviewToEdges:PPViewEdgeRight withInset:0];
        [self.emailField pinInSuperviewToEdges:PPViewEdgeLeft withInset:12];
        [self.emailField pinInSuperviewToEdges:PPViewEdgeTop withInset:25];
        [self.emailField constrainToHeight:54];

        [self.legalDisclaimer pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.emailField inset:30];
        [self.legalDisclaimer pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:20];
        [self.legalDisclaimer sizeToFit];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendPressed];

    return NO;
}

#pragma mark -
#pragma mark PPHSDKEmailViewController
- (void)sendPressed {
//    NSError *error = nil;
//    if (![self.emailField.text isValidEmailAddress:&error]) {
//        [PPHSDKAlertView showAlertWithTitle:SDK_LOCALIZED_STRING(@"PPH_InvalidEmail", nil)
//                                    message:SDK_LOCALIZED_STRING(@"PPH_InvalidEmailMessage", nil)
//                          cancelButtonTitle:SDK_LOCALIZED_STRING(@"PPH_EMVSDK_OKLabel", nil)
//                          otherButtonTitles:nil
//                               showActivity:NO
//                           selectionHandler:^(PPHSDKAlertView *alertView, UIButton *button, NSInteger selectedIndex) {
//                               [self.emailField becomeFirstResponder];
//                           }];
//    } else {
        [self.emailField resignFirstResponder];
        [self sendReceipt];
//    }
}

- (void)sendReceipt {
    self.callback(nil, @{@"name": @"emailOrSms", @"value":self.emailField.text});
}

//- (void)dismissAlert {
//    [self.alert dismissAnimated:YES];
//    self.alert = nil;
//}

@end
