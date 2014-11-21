//
//  STViewController.h
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/14/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface STOauthLoginViewController : UIViewController <
			UITextFieldDelegate,
			UIPickerViewDelegate,		
			UIPickerViewDataSource
>

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *serviceURLLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UILabel *selectedStage;
@property (weak, nonatomic) IBOutlet UIView *selectedStageView;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@property (nonatomic) IBOutlet PPHMerchantInfo *merchant;

- (IBAction)loginPressed:(id)sender;
- (IBAction)settingsPressed:(id)sender;

- (void) setActiveMerchantWithAccessTokenDict:(NSDictionary *)JSON;
@end
