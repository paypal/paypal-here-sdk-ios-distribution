//
//  STReaderInfoViewController.h
//  SimplerTransaction
//
//  Created by Cotter, Vince on 12/30/13.
//  Copyright (c) 2013 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PayPalHereSDK.h>
#import <PayPalHereSDK/PPHCardReaderDelegate.h>

@interface STReaderInfoViewController : UIViewController <
  	PPHSimpleCardReaderDelegate
>


@property (weak, nonatomic) NSString *readerType;
@property (weak, nonatomic) NSString *readerFamily;
@property (weak, nonatomic) NSString *friendlyName;

// Some 'card reader metadata' properties may, or may not be available - 
// some metadata only appears after a swipe (for a mag swipe reader),
// or if you've attached to a Miura device. In the implementation the
// UILabels corresponding to these properties are only visible if the
// property is non-nil:
@property (weak, nonatomic) NSString *serialNumber;
@property (weak, nonatomic) NSString *firmwareRevision;
@property (weak, nonatomic) NSString *batteryLevel;

@property (weak, nonatomic) IBOutlet UILabel *readerTypeLabel;
@property (weak, nonatomic) IBOutlet UILabel *readerFamilyLabel;
@property (weak, nonatomic) IBOutlet UILabel *friendlyNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *serialNumberLabel;
@property (weak, nonatomic) IBOutlet UILabel *firmwareRevisionLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;

// Unless card reader metadata is detected, we want the "label labels"
// which identify the serial number, firmware revision, and battery
// level to be invisible. So we need to make these IBOutlets as well:
@property (weak, nonatomic) IBOutlet UILabel *serialNumberLabelLabel;
@property (weak, nonatomic) IBOutlet UILabel *firmwareRevisionLabelLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabelLabel;

@end
