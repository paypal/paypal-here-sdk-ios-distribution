//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPHCardReaderDelegate.h"

/*!
 * The CardReaderWatcher basically translates between untyped NotificationCenter events
 * and a clean delegate interface without sacrificing the ability to have multiple listeners
 */
@interface PPHCardReaderWatcher : NSObject
/*!
 * Initialize a watcher to send events to the delegate
 * @param delegate the receiver of card reader events
 */
-(id)initWithDelegate: (id<PPHCardReaderDelegate>) delegate;

@end
