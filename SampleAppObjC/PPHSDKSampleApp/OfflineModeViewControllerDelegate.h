//
//  OfflineModeViewControllerDelegate.h
//  PPHSDKSampleApp
//
//  Created by Patil, Mihir on 7/5/18.
//  Copyright © 2018 Patil, Mihir. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol OfflineModeViewControllerDelegate <NSObject>
-(void) offlineMode :(OfflineModeViewController*)controller :(BOOL)isOffline;
@end
