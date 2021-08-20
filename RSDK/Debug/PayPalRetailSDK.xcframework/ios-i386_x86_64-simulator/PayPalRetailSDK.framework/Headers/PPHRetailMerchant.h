//
//  PPHRetailMerchant.h
//

#import <Foundation/Foundation.h>
#import "SdkCredential.h"
#import "PPHRetailMerchantStatus.h"
#import "PPHRetailMerchantUserInfo.h"

/**
 * PayPal Here Merchant
 */
@interface PPHRetailMerchant : NSObject

/**
 * Credentials
 */
@property (nonatomic, strong) SdkCredential *credential;

/**
 * Merchant Status
 */
@property (nonatomic, strong) PPHRetailMerchantStatus *status;

/**
 * Merchant user  info
 */
@property (nonatomic, strong) PPHRetailMerchantUserInfo *userInfo;

/**
 * For use by the PayPal Here app with initializePPHRetailMerchant. Set the access token for logging.
 */
@property (nonatomic, copy) NSString *logglyAccessToken;

/**
 * Pairing id
 */
@property (nonatomic, copy) NSString *pairingId;

@end

