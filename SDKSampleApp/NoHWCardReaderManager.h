//
//  NoHWCardReaderManager.h
//  NOHWSampleApp
//
//  Created by Samuel Jerome on 7/30/14.
//  Copyright (c) 2014 PayPalHereSDK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <PayPalHereSDK/PPHCardSwipeData.h>

@interface NoHWCardReaderManager : NSObject
+(void) listenForCardsWithCallbackBlock:(void (^)(PPHCardSwipeData *))readyBlock andDeviceConnectedBlock:(void (^)(BOOL))conChangedBlock;
+(void) stopListening;
+(BOOL)isDeviceConnected;
@end
