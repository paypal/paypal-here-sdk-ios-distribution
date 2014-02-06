//
//  STItemizedPurchaseButton.h
//  SimplerTransaction
//
//  Created by Cotter, Vince on 1/10/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface STItemizedPurchaseButton : NSObject

@property (nonatomic,strong) UIButton *button;

- (id) initWithButton:(UIButton *)aButton;
- (void) itemWasTouchedUpAndDidHold;
- (void) itemWasTouchedUp;

@end


