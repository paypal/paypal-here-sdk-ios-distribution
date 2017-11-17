//
//  ViewController.h
//  RetailSDKTestApp
//
//  Created by Max Metral on 4/6/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property (weak) IBOutlet NSButton *chargeButton;
@property (weak) IBOutlet NSButton *enterPanButton;
@property (weak) IBOutlet NSTextField *amountField;
@property (weak) IBOutlet NSTextField *statusLabel;

- (IBAction)chargeButtonPressed:(id)sender;

@end

