//
//  PPReceiptSMSEntryController.m
//  PayPal Retail SDK
//
//  Created by Pavlinsky, Matthew on 4/8/16.
//  Copyright (c) 2016 PayPal. All rights reserved.
//

#import "PPReceiptSMSEntryController.h"
#import "PayPalRetailSDK+Private.h"
#import "PayPalRetailSDKStyles.h"
#import "PlatformView+PPAutoLayout.h"
#import "PPRetailPhoneFormatter.h"
#import "PPRetailCoreServices.h"
#import "PPAlertView.h"


////////////////////////////////////////////////////////////////////////////////////////////////////
@interface PPReceiptSMSEntryController ()<
UITextFieldDelegate
>

@property (nonatomic, strong) PPRetailReceiptSMSEntryViewContent *content;
@property (nonatomic, strong) NSString *suggestedPhone;
@property (copy) PPReceiptDestinationCallback callback;
@property (nonatomic, copy) NSString *countryCode;
@property (nonatomic, strong)PPRetailPhoneFormatter *phoneFormatter;

@property (nonatomic, strong) UITextField *phoneNumberField;
@property (nonatomic, strong) UIButton *centerButton;
@property (nonatomic, strong) UILabel *legalDisclaimer;
@property (nonatomic, strong) UIPickerView *countryCodePicker;
@property (nonatomic, strong) UITextField *countryCodeField;
@property (nonatomic, strong) NSDictionary *phoneFormats;
@property (nonatomic, strong) PPAlertView *currentAlertView;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////
@implementation PPReceiptSMSEntryController

#pragma mark -
#pragma mark init

- (instancetype)initWithContent:(PPRetailReceiptSMSEntryViewContent *)content
                 suggestedPhone:(NSString *)suggestedPhone
                       callback:(PPReceiptDestinationCallback)callback {
    if (self = [super init]) {
        self.content = content;
        self.suggestedPhone = suggestedPhone;
        self.callback = callback;
    }
    return self;
}

#pragma mark -
#pragma mark UIView

- (void)loadView {
    [super loadView];
    
    self.phoneFormats = [PPRetailCoreServices countryPhoneCodesList];

    self.phoneNumberField = [UITextField new];
    [self.phoneNumberField setPlaceholder:self.content.placeholder];
    [self.phoneNumberField setFont:[PayPalRetailSDKStyles boldFontWithSize:15.0f]];
    [self.phoneNumberField setTranslatesAutoresizingMaskIntoConstraints:NO];
    self.phoneNumberField.keyboardType = UIKeyboardTypePhonePad;
    self.phoneNumberField.delegate = self;
    self.phoneNumberField.returnKeyType = UIReturnKeySend;
    
    UIImageView *bubbleImage = [[UIImageView alloc] initWithImage:[PayPalRetailSDK sdkImageNamed:@"ic_text"]];
    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, bubbleImage.frame.size.width * 1.5, bubbleImage.frame.size.height)];
    [leftView addSubview:bubbleImage];
    
    self.phoneNumberField.leftView = leftView;
    self.phoneNumberField.leftViewMode = UITextFieldViewModeAlways;
    [self.view addSubview:self.phoneNumberField];
    
    self.countryCodeField = [UITextField new];
    self.countryCodeField.delegate = self;
    
    UIView *ccLeftView = [[UIView alloc] initWithFrame:leftView.frame];
    self.countryCodeField.leftView = ccLeftView;
    self.countryCodeField.leftViewMode = UITextFieldViewModeAlways;

    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        self.centerButton = [UIButton new];
        [self.centerButton addTarget:self action:@selector(sendPressed) forControlEvents:UIControlEventTouchUpInside];
        [self.centerButton setTitle:self.content.sendButtonTitle forState:UIControlStateNormal];
        [self.centerButton setBackgroundColor:UIColorFromRGB(0x33c2ff)];
        [self.view addSubview:self.centerButton];
        [self.centerButton setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self.centerButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [self.centerButton.titleLabel setFont:[PayPalRetailSDKStyles boldFontWithSize:21]];
        
        self.countryCodePicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
        self.navigationItem.rightBarButtonItem = nil;
        self.countryCodeField.inputView = [UIView new];
        self.countryCodePicker.hidden = YES;
        [self.view addSubview:self.countryCodePicker];
    } else {
        UIBarButtonItem *text = [[UIBarButtonItem alloc] initWithTitle:self.content.sendButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(sendPressed)];
        self.navigationItem.rightBarButtonItem = text;
        
        self.countryCodePicker = [[UIPickerView alloc] initWithFrame:CGRectZero];
        self.countryCodeField.inputView = self.countryCodePicker;
    }
    
    [self.countryCodeField setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.countryCodeField setTextColor:UIColorFromRGB(0x33c2ff)];
    [self.view addSubview:self.countryCodeField];
    
    self.countryCodePicker.delegate = self;
    self.countryCodePicker.dataSource = self;
    [self.countryCodePicker setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    self.countryCode = [PayPalRetailSDK getMerchantCountryCode];
    [self.countryCodePicker selectRow:[[self.phoneFormats allKeys] indexOfObject:self.countryCode] inComponent:0 animated:NO];
    [self.view addSubview:self.phoneNumberField];
    
    self.legalDisclaimer = [UILabel new];
    [self.legalDisclaimer setText:self.content.disclaimer];
    [self.legalDisclaimer setFont:[PayPalRetailSDKStyles lightFontWithSize:15]];
    [self.legalDisclaimer setTextColor:[PayPalRetailSDKStyles primaryTextColor]];
    [self.legalDisclaimer setNumberOfLines:0];
    [self.legalDisclaimer setLineBreakMode:NSLineBreakByWordWrapping];
    [self.legalDisclaimer setTextAlignment:NSTextAlignmentCenter];
    [self.legalDisclaimer setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.legalDisclaimer];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.content.title;
    [self.view setNeedsUpdateConstraints];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.phoneNumberField becomeFirstResponder];
}

- (void)setCountryCode:(NSString *)countryCode {
    _countryCode = [countryCode copy];
    self.phoneFormatter = [PPRetailPhoneFormatter phoneFormatterWithCountryCode:self.countryCode];
    self.countryCodeField.text = [self displayStringForCountryCode:self.countryCode];
    [self numberChanged];
}

- (void)numberChanged {
    NSString *formatted = [self.phoneFormatter formatPhone:self.phoneNumberField.text];
    if (![self.phoneNumberField.text isEqualToString:formatted]) {
        self.phoneNumberField.text = formatted;
    }
}

- (void)updateViewConstraints {
    [super updateViewConstraints];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        [self.phoneNumberField pinInSuperviewToEdges:PPViewEdgeRight withInset:0];
        [self.phoneNumberField pinInSuperviewToEdges:PPViewEdgeLeft withInset:12];
        [self.phoneNumberField pinInSuperviewToEdges:PPViewEdgeTop withInset:25];
        [self.phoneNumberField constrainToHeight:54];
        
        [self.countryCodeField pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.phoneNumberField inset:0];
        [self.countryCodeField pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:0];
        [self.countryCodeField constrainToHeight:40];
        
        if (self.countryCodePicker.superview) {
            [self.countryCodePicker pinInSuperviewToEdges:PPViewEdgeBottom withInset:0];
        }
        
        [self.legalDisclaimer pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.countryCodeField inset:10];
        //[self.legalDisclaimer pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.phoneNumberField inset:10];
        [self.legalDisclaimer pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:20];
        [self.legalDisclaimer sizeToFit];
    } else {
        [self.phoneNumberField pinInSuperviewToEdges:PPViewEdgeTop withInset:64];
        [self.phoneNumberField constrainToWidth:480];
        [self.phoneNumberField centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
        [self.phoneNumberField constrainToHeight:54];
        
        [self.countryCodeField pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.phoneNumberField inset:0];
        [self.countryCodeField constrainToWidth:480];
        [self.countryCodeField constrainToHeight:44];
        [self.countryCodeField centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
        
        [self.countryCodePicker pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.countryCodeField inset:213];
        [self.countryCodePicker centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
        
        [self.centerButton centerInSuperviewOnAxis:NSLayoutAttributeCenterX];
        [self.centerButton pinInSuperviewToEdges:PPViewEdgeBottom withInset:382];
        [self.centerButton constrainToHeight:54];
        [self.centerButton constrainToWidth:220];

        [self.legalDisclaimer pinEdge:NSLayoutAttributeTop toEdge:NSLayoutAttributeBottom ofView:self.centerButton inset:10];
        [self.legalDisclaimer pinInSuperviewToEdges:PPViewEdgesHorizontal withInset:100];
        [self.legalDisclaimer sizeToFit];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self sendPressed];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return textField != self.countryCodeField;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && textField == self.countryCodeField) {
        self.countryCodePicker.hidden = NO;
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    if ((UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) && textField == self.countryCodeField) {
        self.countryCodePicker.hidden = YES;
    }
}

#pragma mark -
#pragma mark PPHSendTextReceiptViewController
- (void)sendPressed {
    [self.phoneNumberField resignFirstResponder];
    
    if (![self validateMobileNumber]) {
        return;
    }
    [self sendReceipt];
}

- (void)sendReceipt {
    NSString *completePhoneNumber = [self getCompleteMobileNumber];
    self.callback(nil, @{@"name": @"emailOrSms", @"value":completePhoneNumber});

}

- (NSString *)getCompleteMobileNumber {
    NSString *number = [[self.phoneNumberField.text componentsSeparatedByCharactersInSet:
                         [[NSCharacterSet characterSetWithCharactersInString:@"1234567890"] invertedSet]]
                        componentsJoinedByString:@""];
    NSString *countryCode = [self countryPhoneCodeForCountryCode:self.countryCode];
    //first remove country code
    if ([number hasPrefix:countryCode]) {
        number = [number stringByReplacingCharactersInRange:NSMakeRange(0, countryCode.length) withString:@""];
    }
    //then append it with +
    if (![countryCode isEqualToString:@""]) {
        number = [NSString stringWithFormat:@"+%@-%@", countryCode, number];
    } else {
        number = [NSString stringWithFormat:@"+%@", number];
    }
    
    return number;
    
}

- (BOOL)validateMobileNumber {
    if (self.phoneNumberField && self.phoneNumberField.text.length > 0 && self.countryCode.length > 0) {
        return YES;
    }
    [self displayInvalidMobileNumberMessage];
    return NO;
}

-(void)displayInvalidMobileNumberMessage {
    
    if (self.currentAlertView) {
        [self.currentAlertView dismissAnimated:YES];
        self.currentAlertView = nil;
    }
    
    self.currentAlertView = [PPAlertView showAlertWithTitle:RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Title_InvalidMobileNumber", nil)
                                                    message:RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Message_InvalidMobileNumber", nil)
                                                    cancelButtonTitle:RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_OKLabel", nil)
                                                    otherButtonTitles:nil
                                                    showActivity:FALSE selectionHandler:^(PPAlertView *alertView, NSInteger selectedIndex) {
        
    }];
}

#pragma mark -
#pragma mark UIPickerViewDatasource
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.phoneFormats.count;
    
}

- (NSString *)countryCodeForRow:(NSInteger)row {
    return [self.phoneFormats allKeys][row];
}

#pragma mark -
#pragma mark UIPickerViewDelegate
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self displayStringForCountryCode:[self countryCodeForRow:row]];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    self.countryCode = [self countryCodeForRow:row];
}

- (NSString *)countryForCountryCode:(NSString *)countryCode {
    static NSDictionary *ccMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ccMap = @{@"US" : RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_US", nil),
                  @"CA" : RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_CA", nil),
                  @"HK" : RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_HK", nil),
                  @"JP" : RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_JP", nil),
                  @"AU" : RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_AU", nil),
                  @"GB" : RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_UK", nil),
                  @"DEFAULT" : RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_Other", nil)};
    });
    return ((NSString *)ccMap[countryCode]);
}

- (NSString *)countryPhoneCodeForCountryCode:(NSString *)countryCode {
    return self.phoneFormats[countryCode][@"CountryCode"];
}

- (NSString *)displayStringForCountryCode:(NSString *)cc {
    if ([cc isEqualToString:@"DEFAULT"]) {
        return RSDK_LOCALIZED_STRING(@"PPH_EMVSDK_Country_Other", nil);
    }
    return [NSString stringWithFormat:@"(+%@) %@", [self countryPhoneCodeForCountryCode:cc], [self countryForCountryCode:cc]];
}
@end
