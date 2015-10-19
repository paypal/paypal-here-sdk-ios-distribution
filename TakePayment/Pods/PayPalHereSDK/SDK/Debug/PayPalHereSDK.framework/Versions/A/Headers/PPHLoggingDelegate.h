//
//  PayPalHereSDK
//
//  Copyright (c) 2013 PayPal. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 * For debugging purposes it can be helpful to see our internal logs.
 * Implement this protocol and set the logging delegate on PayPalHereSDK.
 * You should generally not set this delegate in production code as it will
 * have a theoretical performance impact (we'll call respondsToSelector a lot).
 * If you respond to a given selector, we'll put the message together, which will
 * cause a bunch of string munging to happen. So basically, use this when you
 * mean it, not just on a whim.
 */
@protocol PPHLoggingDelegate <NSObject>
@optional
/*!
 * Log a message considered to be indicative of an error.
 * @param message The fully formatted log message.
 */
-(void)logPayPalHereError: (NSString*) message;
/*!
 * Log a message considered to be a potential issue affecting proper function.
 * @param message The fully formatted log message.
 */
-(void)logPayPalHereWarning: (NSString*) message;
/*!
 * Log informational events.
 * @param message The fully formatted log message.
 */
-(void)logPayPalHereInfo: (NSString*) message;
/*!
 * Log fxn tracing events.
 * @param message The fully formatted log message.
 */
-(void)logPayPalHereTrace: (NSString*) message;
/*!
 * Log debug/verbose events.
 * @param message The fully formatted log message.
 */
-(void)logPayPalHereDebug: (NSString*) message;

/*!
 * Log a message considered to be indicative of an error for hardware interactions.
 * @param message The fully formatted log message.
 */
- (void)logPayPalHereHardwareError:(NSString *)message;

/*!
 * Log a message considered to be a potential issue affecting proper function for hardware interactions.
 * @param message The fully formatted log message.
 */
- (void)logPayPalHereHardwareWarning:(NSString *)message;

/*!
 * Log informational events for hardware interactions.
 * @param message The fully formatted log message.
 */
- (void)logPayPalHereHardwareInfo:(NSString *)message;

/*!
 * Cause the logger to send all its queued messages now.
 */
-(void)flush;

@end
