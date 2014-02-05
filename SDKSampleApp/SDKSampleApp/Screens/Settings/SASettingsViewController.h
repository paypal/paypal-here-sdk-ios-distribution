//
//  SASettingsViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHCardReaderDelegate.h>


@interface SASettingsViewController : UIViewController <
PPHSimpleCardReaderDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *sdkVersion;
@property (weak, nonatomic) IBOutlet UIButton *readerDetectedButton;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *detectingReaderSpinny;



- (IBAction)onReaderDetailsPressed:(id)sender;

@end
