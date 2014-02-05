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

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loginInProgress;
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UILabel *serviceURLLabel;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;

@property (nonatomic) IBOutlet PPHMerchantInfo *merchant;

- (IBAction)loginPressed:(id)sender;

- (void) setActiveMerchantWithAccessTokenDict:(NSDictionary *)JSON;
@end
