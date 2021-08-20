//
//  SdkCredential.h
//

#import <Foundation/Foundation.h>

/**
 * For use with initializeMerchantWithCredentials
 */
@interface SdkCredential : NSObject

- (id)init __attribute__((unavailable("init not available, use initWith...")));

/**
 * Initialize with access token, token refresh url and environment
 */
- (id)initWithAccessToken:(NSString *)aToken refreshUrl:(NSString *)rUrl environment:(NSString *)env;

/**
 * Initialize with environment, set other properties later
 */
- (id)initWithEnvironment:(NSString *)env;

/**
 * Set the token refresh url
 */
-(SdkCredential *)setTokenRefreshUrl:(NSString *)refreshUrl;

/**
 * Set the firmware update repo
 */
-(SdkCredential *)setRepo:(NSString *)repository;

/**
 * Set first party credentials: clientId and appSecret
 */
-(SdkCredential *)setFirstPartyCredentials:(NSString *)clientId appSecret:(NSString *)appSecret;

/**
 * Set third party credentials: accessToken
 */
-(SdkCredential *)setThirdPartyCredentials:(NSString *)accessToken;

/**
 * Access token
 */
@property (nonatomic, copy) NSString *accessToken;

/**
 * Refresh url
 */
@property (nonatomic, copy) NSString *refreshUrl;

/**
 * Refresh token
 */
@property (nonatomic, copy) NSString *refreshToken;

/**
 * Client id
 */
@property (nonatomic, copy) NSString *clientId;

/**
 * App secret
 */
@property (nonatomic, copy) NSString *appSecret;

/**
 * Environment
 */
@property (nonatomic, copy) NSString *environment;

/**
 * Firmware update repo
 */
@property (nonatomic, copy) NSString *repository;

@end
