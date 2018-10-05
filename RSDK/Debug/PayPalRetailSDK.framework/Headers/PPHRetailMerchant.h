//
//  PPHRetailMerchant.h
//

#import <Foundation/Foundation.h>
#import "SdkCredential.h"
#import "PPHRetailMerchantStatus.h"
#import "PPHRetailMerchantUserInfo.h"

@interface PPHRetailMerchant : NSObject

@property (nonatomic, strong) SdkCredential *credential;
@property (nonatomic, strong) PPHRetailMerchantStatus *status;
@property (nonatomic, strong) PPHRetailMerchantUserInfo *userInfo;
@property (nonatomic, copy) NSString *logglyAccessToken;

@end

