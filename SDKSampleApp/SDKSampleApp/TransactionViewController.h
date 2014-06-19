//
//  TransactionViewController.h
//  SimplerTransaction
//
//  Created by Cotter, Vince on 11/19/13.
//  Copyright (c) 2013 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PayPalHereSDK/PPHTransactionManager.h>

@interface TransactionViewController : UIViewController <
UITableViewDataSource
>

@property (weak, nonatomic) IBOutlet UILabel *enterAmountLabel;
@property (weak, nonatomic) IBOutlet UITableView *shoppingCartTable;
@property (weak, nonatomic) IBOutlet UILabel *longPressExplanationLabel;
@property (weak, nonatomic) IBOutlet UIButton *purchaseButton;


@end


