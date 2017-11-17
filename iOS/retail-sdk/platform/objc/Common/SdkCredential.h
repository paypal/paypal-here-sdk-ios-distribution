//
//  SdkCredential.h
//

#import <Foundation/Foundation.h>

@interface SdkCredential : NSObject

@property (nonatomic, copy) NSString* accessToken;

@property (nonatomic, copy) NSString* refreshUrl;

@property (nonatomic, copy) NSString* refreshToken;

@property (nonatomic, copy) NSString* clientId;

@property (nonatomic, copy) NSString* environment;

@property (nonatomic, copy) NSString* repository;

@end
