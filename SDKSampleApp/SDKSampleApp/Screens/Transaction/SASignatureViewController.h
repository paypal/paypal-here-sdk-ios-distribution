//
//  SASignatureViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/3/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHSignatureView.h>

@class PPHTransactionRecord;

@interface SASignatureViewController : UIViewController

@property (nonatomic,strong) IBOutlet UIButton* charge;
@property (nonatomic,strong) IBOutlet PPHSignatureView* signature;


- (IBAction)onDonePressed:(id)sender;
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil transactionRecord:(PPHTransactionRecord*)capturedPayment;

@end
