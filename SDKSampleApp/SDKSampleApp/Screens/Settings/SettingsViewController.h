//
//  SettingsViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHCardReaderDelegate.h>
#import <CoreLocation/CLLocationManagerDelegate.h>


@interface SettingsViewController : UIViewController <
PPHSimpleCardReaderDelegate,
CLLocationManagerDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *sdkVersion;
@property (weak, nonatomic) IBOutlet UIButton *readerDetectedButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *detectingReaderSpinny;
@property (weak, nonatomic) IBOutlet UISwitch *checkinSwitch;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *checkinMerchantSpinny;

- (IBAction)onReaderDetailsPressed:(id)sender;
- (IBAction)onCheckinButtonToggled:(id)sender;

@end
