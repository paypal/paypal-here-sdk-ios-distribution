//
//  AddTipViewController.h
//  SDKSampleApp
//
//  Created by Angelini, Dom on 2/26/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PPHInvoice;

@interface AddTipViewController : UIViewController
<
UITextFieldDelegate
>

@property (weak, nonatomic) IBOutlet UILabel *purchaseTotal;
@property (weak, nonatomic) IBOutlet UITextField *tipToAdd;
@property (weak, nonatomic) IBOutlet UILabel *grandTotalWithTip;
@property (weak, nonatomic) IBOutlet UISegmentedControl *tipType;
@property (weak, nonatomic) IBOutlet UISegmentedControl *percentLevel;

-(IBAction)onCancel:(id)sender;
-(IBAction)onAddTip:(id)sender;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
           forInvoice:(PPHInvoice *)invoice;
@end
