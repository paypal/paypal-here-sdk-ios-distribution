//
//  RUAProgressHandler.h
//  ROAMreaderUnifiedAPI
//
//  Created by Bin Lang on 9/20/17.
//  Copyright © 2017 ROAM. All rights reserved.
//
#import "RUADeviceResponseHandler.h"

@protocol RUAProgressHandler <NSObject>

/**
 * Called when the roam reader indicates progress while processing the command.
 *
 * @param message the message
 * @param additionalMessage the addtional message
 * @see RUAProgressMessage
 */
-(void)onProgress:(RUAProgressMessage)message andAddtionalMessage:(NSString *)additionalMessage;

@end
