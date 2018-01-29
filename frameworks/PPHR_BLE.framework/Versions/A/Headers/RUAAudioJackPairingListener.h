//
//  AudioJackPairingListener.m
//  ROAMreaderUnifiedAPI
//
//  Created by Vinoth Adaikkappan on 11/30/15.
//  Copyright © 2015 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 * Interface definition for callback methods to be invoked
 * during the process of pairing a keypadless & displayless
 * Bluetooth card reader via an audio jack connection.
 * <br>
 * Currently only supported by the RP450c device manager.
 */


#ifndef ROAMreaderUnifiedAPI_RUAAudioJackPairingListener_h
#define ROAMreaderUnifiedAPI_RUAAudioJackPairingListener_h

@protocol RUAAudioJackPairingListener <NSObject>

/**
 * Called during the pairing process to let the application display
 * the reader and mobile passkeys.
 */

- (void)onPairConfirmation:(NSString *)readerPasskey mobileKey:(NSString *) mobilePasskey;

/**
 * Called to indicate that the pairing process has successfully completed.
 */

- (void)onPairSucceeded;

/**
 * Called to indicate that the device manager does not support audio jack pairing.
 */
- (void) onPairNotSupported;

/**
 * Called to indicate that the pairing process failed.
 */
- (void) onPairFailed;

@optional

/**
 * Called during the pairing process to let the application display
 * the reader and mobile passkeys along with RUADevice Object.
 */
- (void)onPairConfirmation:(NSString *)readerPasskey mobileKey:(NSString *) mobilePasskey device:(RUADevice*)device;

/**
 * Called to indicate that the pairing process has successfully completed.
 */

- (void)onPairSucceeded:(RUADevice*)device;

@end

#endif