//
//  STSettingsViewController.h
//  SDKSampleAppWithSource
//
//  Created by Chandrashekar, Sathyanarayan on 11/19/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STSettingsViewController : UIViewController
<
UIPickerViewDataSource,
UIPickerViewDelegate
>

@property (nonatomic, weak) IBOutlet UIPickerView *stagePicker;
@property (nonatomic, weak) IBOutlet UITextField *customStage;
@property (nonatomic, weak) IBOutlet UILabel *stageName;

-(IBAction)customStageButtonPressed:(id)sender;

@end
