//
//  PPHTransactionWatcher.h
//  PayPalHereSDK
//
//  Created by Cotter, Vince on 12/24/13.
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHTransactionManager.h"

/*!
 * The PPHTransactionWatcher follows the standard PPHSDK "Watcher" pattern, translating
 * NotificationCenter events into a delegate interface. A PPHTransactionWatcher "watches"
 * the PPHTransactionManager, granting PPHSDK clients the ability to easily track its
 * comings, goings, and doings.
 */
@interface PPHTransactionWatcher : NSObject
/*!
 * Initialize a watcher to send events to the delegate
 * @param delegate the receiver of transaction manager events
 */
-(id)initWithDelegate: (id<PPHTransactionManagerDelegate>) delegate;

@end

