//
//  STItemizedPurchaseButton.m
//  SimplerTransaction
//
//  Created by Cotter, Vince on 1/10/14.
//  Copyright (c) 2014 PayPal Partner. All rights reserved.
//

#import "STItemizedPurchaseButton.h"

@interface STItemizedPurchaseButton ()
-(void)itemHoldTimer;
-(void)itemTouchDown;
-(void)itemTouchUpInside;
@property BOOL didHold;
@property (nonatomic,strong) NSTimer *timer;
@end

@implementation STItemizedPurchaseButton

- (id) initWithButton:(UIButton *)aButton 
{
	if ((self = [super init])) {
		_button = aButton;
		if (_button != nil) {
			[_button addTarget:self action:@selector(itemTouchDown) forControlEvents:UIControlEventTouchDown];
			[_button addTarget:self action:@selector(itemTouchUpInside) forControlEvents:UIControlEventTouchUpInside];
		}
	}

	return self;
}

-(void)itemHoldTimer
{
	self.timer = nil;
	self.didHold = YES;
}

-(void)itemTouchDown
{
	self.didHold = NO;
	self.timer = 
		[NSTimer scheduledTimerWithTimeInterval:1 
				 target:self 
				 selector:@selector(itemHoldTimer)
				 userInfo:nil
				 repeats:NO];
}

-(void)itemTouchUpInside
{
	if (self.timer) {
		[self.timer invalidate];
	}

	if (self.didHold) {
		self.didHold = NO;
		[self itemWasTouchedUpAndDidHold];
	}
	else {
		[self itemWasTouchedUp];
	}

}

- (void) itemWasTouchedUpAndDidHold
{
	NSLog(@"Button long press!");
}

- (void) itemWasTouchedUp
{
	NSLog(@"Button regular press!");
}


@end



