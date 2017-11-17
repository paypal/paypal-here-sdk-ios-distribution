//
//  CaptureViewController.h
//  RetailSDKTestApp
//
//  Created by Singeetham, Sreepada on 6/5/17.
//  Copyright © 2017 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <PayPalRetailSDK/PayPalRetailSDK.h>
#import <PayPalRetailSDK/PPRetailAuthorizedTransaction.h>

@interface CaptureViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *authorizationIdField;
@property (weak, nonatomic) IBOutlet UITextField *captureAmountField;
@property (weak, nonatomic) IBOutlet UIButton *captureButton;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (nonatomic, strong) PPRetailAuthorizedTransaction *authorizationFromSegue;
@property (nonatomic, strong) PPRetailMerchant *merchant;

-(IBAction)captureButtonPressed:(id)sender;

@end
