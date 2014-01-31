//
//  STTransactionViewController.h
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/19/13.
//  Copyright (c) 2013 PayPalHereSDK. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHCardReaderDelegate.h>
#import <PayPalHereSDK/PPHTransactionManager.h>
#import "STItemizedPurchaseButton.h"

@interface STTransactionViewController : UIViewController <
	UITextFieldDelegate,
  	PPHSimpleCardReaderDelegate,
	PPHTransactionManagerDelegate,
	PPHTransactionControllerDelegate,
	UITableViewDataSource
>

@property (weak, nonatomic) IBOutlet UILabel *enterAmountLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *detectingReaderSpinny;
@property (weak, nonatomic) IBOutlet UIButton *readerDetectedButton;
@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *itemizedModeSegmentedControl;
@property (weak, nonatomic) IBOutlet UIButton *appleButton;
@property (weak, nonatomic) IBOutlet UIButton *bananaButton;
@property (weak, nonatomic) IBOutlet UIButton *orangeButton;
@property (weak, nonatomic) IBOutlet UIButton *strawberryButton;
@property (weak, nonatomic) IBOutlet UITableView *shoppingCartTable;
@property (weak, nonatomic) IBOutlet UILabel *longPressExplanationLabel;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *processingTransactionSpinny;

- (IBAction)itemizedModeChanged:(id)sender;
- (IBAction)onChargePressed:(id)sender;
- (IBAction)onReaderDetailsPressed:(id)sender;
- (IBAction)onManualCardChargePressed:(id)sender;
- (IBAction)onCashChargePressed:(id)sender;

@end


@interface TransactionButton : STItemizedPurchaseButton
- (id) initWithTransactionVC:(STTransactionViewController *)vc forItem:(NSString *)item onButton:(UIButton *)aButton;
@end


