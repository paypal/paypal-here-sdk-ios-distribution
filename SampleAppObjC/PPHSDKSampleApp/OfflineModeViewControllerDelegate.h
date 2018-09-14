//
//  OfflineModeViewControllerDelegate.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OfflineModeViewControllerDelegate <NSObject>
@required
-(void) offlineModeController :(OfflineModeViewController*)controller offline:(BOOL)isOffline;
@end
