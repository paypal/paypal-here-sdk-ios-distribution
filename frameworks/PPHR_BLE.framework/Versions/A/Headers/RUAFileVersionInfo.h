//
//  RUAReaderFileVersionInfo.h
//  RUATestApplication
//
//  Created by Vinoth Adaikkappan on 4/15/15.
//  Copyright (c) 2015 ROAM. All rights reserved.
//

#import <Foundation/Foundation.h>
#ifdef RUA_MFI
#import <LandiSDK_MFI/LDTmsFileVersionInfo.h>
#else
#import <LandiSDK_BLE/LDTmsFileVersionInfo.h>
#endif

@interface RUAFileVersionInfo : NSObject


@property (nonatomic, strong) NSString *platform;
@property (nonatomic, strong) NSString *subPlatform;
@property (nonatomic, strong) NSString *fileType;
@property (nonatomic, strong) NSString *maintainerId;
@property (nonatomic, strong) NSString *fileLevel;
@property (nonatomic, strong) NSString *fileSN;
@property (nonatomic, strong) NSString *version;
@property (nonatomic, strong) NSString *dependVer;
@property (nonatomic, strong) NSString *verFlag;
@property (nonatomic, strong) NSString *year;
@property (nonatomic, strong) NSString *month;
@property (nonatomic, strong) NSString *day;

// This group of members represents additional info about files already on terminal.

@property (nonatomic, strong) NSString *customerId;
@property (nonatomic, strong) NSString *compatibilityMatrix;

- (id)initWithUNSFile:(LDTmsFileVersionInfo *)ldtFileversionInfo;
- (id)initWithUNSJson:(NSString *)UNSJson;
- (id)init:(NSString *)infoFromReadVersion;
- (NSString *)toString;
- (BOOL)namePortionMatches:(RUAFileVersionInfo *)info;
/**
 * Returns 1 if this object's versioning members are newer,
 * 0 if the same, -1 if older than the ones of the object passed in..
 */
- (int)compareWith:(RUAFileVersionInfo *)info;

@end
