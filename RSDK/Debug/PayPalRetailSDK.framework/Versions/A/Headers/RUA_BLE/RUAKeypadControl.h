//
//  RUAKeypadControl.h
//  ROAMreaderUnifiedAPI
//
//  Created by Russell Kondaveti on 2/25/14.
//  Copyright (c) 2014 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
	RUALanguageCodeENGLISH = 0,
	RUALanguageCodeFRENCH = 1
}RUALanguageCode;
/**
 * KeyPadControl provides interface to control the keypad of ROAM device.<br>
 * @author rkondaveti
 */
@protocol RUAKeypadControl <NSObject>
/**
 * This methods sends the command to keypad to set click duration and click frequency. <br>
 * @param clickDuration
 * @param clickFrequnecy
 * @param handler
 */
- (void)setClickFrequency:(int)clickDuration frequency:(int)clickFrequnecy response:(OnResponse)response;

/**
 * This methods sends the command to keypad to prompt for PIN with TDES DUKPT ISO PIN Block encryption. <br>
 * When the reader processes the command, it returns the result as a map to
 * the callback method onResponse on the DeviceResponseHandler passed.<br>
 * The map passed to the onResponse callback contains the following
 * parameters as keys, <br>
 * - Parameter.ResponseCode (ResponseCode enumeration as value)<br>
 * - Parameter.ErrorCode (if not successful, ErrorCode enumeration as value)<br>
 * - Parameter.EncryptedIsoPinBlock<br>
 * - Parameter.KSN<br>
 * @param languageCode
 * @param pinBlockFormat
 * @param keyLocator
 * @param cardLast4Digits
 * @param macData
 * @param clearOnlyLastDigitEntered
 * @param interDigitTimeout
 * @param handler
 */
- (void)promptPinTDESBlockWithEncryptedPAN:(RUALanguageCode)languageCode pinBlockFormat:(NSString *)pinBlockFormat keyLocator:(NSString *)keyLocator
                           cardLast4Digits:(NSString *)cardLast4Digits macData:(NSString *)macData clearOnlyLastDigitEntered:(BOOL)clearOnlyLastDigitEntered
                         interDigitTimeout:(int)interDigitTimeout response:(OnResponse)response;

/**
 * This methods sends the command to keypad to prompt for PIN with Master and session key encryption. <br>
 * When the reader processes the command, it returns the result as a map to
 * the callback method onResponse on the DeviceResponseHandler passed.<br>
 * The map passed to the onResponse callback contains the following
 * parameters as keys, <br>
 * - Parameter.ResponseCode (ResponseCode enumeration as value)<br>
 * - Parameter.ErrorCode (if not successful, ErrorCode enumeration as value)<br>
 * - Parameter.EncryptedIsoPinBlock<br>
 * - Parameter.KSN<br>
 * @param languageCode
 * @param pinBlockFormat
 * @param keyLocator
 * @param cardLast4Digits
 * @param clearOnlyLastDigitEntered
 * @param interDigitTimeout
 * @param handler
 */
- (void)promptPinMasterSessionKeyWithEncryptedPAN:(RUALanguageCode)languageCode pinBlockFormat:(NSString *)pinBlockFormat keyLocator:(NSString *)keyLocator
                                  cardLast4Digits:(NSString *)cardLast4Digits clearOnlyLastDigitEntered:(BOOL)clearOnlyLastDigitEntered
                                interDigitTimeout:(int)interDigitTimeout response:(OnResponse)response;


/**
 This method sends the command to keypad to collect card data (PAN, expiry date, CVC)
 from the user.<br>
 When the reader processes the command, it returns the result as a map to  the OnResponse block passed.<br>
 The map passed to the onResponse callback contains the following parameters as keys, <br>
 @param publicKey the public key
 @param response OnResponse block
 @param progress OnProgress block
 
 @see PublicKey
 
 */

- (void)retrieveKeyedCardData:(OnProgress)progress response:(OnResponse)response;



@end
