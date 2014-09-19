//
//  ViewController.h
//  EMVAccreditationSampleApp
//
//  Created by Curam, Abhay on 6/24/14.
//  Copyright (c) 2014 ___FULLUSERNAME___. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PayPalHereSDK.h>

@interface EMVOauthLoginViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate, UIActionSheetDelegate>

@property(nonatomic, strong) PPHMerchantInfo *merchant;
@property(nonatomic, strong) NSMutableString *serviceHostUrl;
@property(nonatomic, strong) NSMutableString *urlForTheSdkToUse;
@property(nonatomic, strong) NSMutableArray *serviceHostUrlArray;
@property(nonatomic, strong) NSDictionary *sdkBaseUrlDict;

@property(weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property(weak, nonatomic) IBOutlet UISegmentedControl *segControl;
@property(weak, nonatomic) IBOutlet UITextField *usernameField;
@property(weak, nonatomic) IBOutlet UITextField *passwordField;

- (IBAction)serviceHostSegmentedControlChanged:(id)sender;
- (IBAction)loginPressed:(id)sender;
- (IBAction)usernameFieldReturned:(id)sender;
- (IBAction)passwordFieldReturned:(id)sender;

- (void) setActiveMerchantWithAccessTokenDict:(NSDictionary *)JSON;


@end
