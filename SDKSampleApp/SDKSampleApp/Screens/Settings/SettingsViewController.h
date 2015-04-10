//
//  SettingsViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CLLocationManagerDelegate.h>
#import "PayPalHereSDK.h"
#import "STServices.h"

@interface SettingsViewController : UIViewController <
PPHSimpleCardReaderDelegate,
CLLocationManagerDelegate,
UITextFieldDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *sdkVersion;
@property (weak, nonatomic) IBOutlet UIButton *readerDetectedButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *detectingReaderSpinny;
@property (weak, nonatomic) IBOutlet UISwitch *checkinSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *checkinMerchantSpinny;
@property (weak, nonatomic) IBOutlet UILabel *sampleAppVersion;
@property (weak, nonatomic) IBOutlet UISegmentedControl *paymentFlowType;
@property (weak, nonatomic) IBOutlet UILabel *captureTolerance;

- (IBAction)onReaderDetailsPressed:(id)sender;
- (IBAction)onCheckinButtonToggled:(id)sender;
- (IBAction)onPaymentFlowTypePressed:(id)sender;
@end
