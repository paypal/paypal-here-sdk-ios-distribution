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


@property (strong,nonatomic) NSString* platform;
@property (strong,nonatomic) NSString* subPlatform;
@property (strong,nonatomic) NSString* fileType;
@property (strong,nonatomic) NSString* maintainerId;
@property (strong,nonatomic) NSString* fileLevel;
@property (strong,nonatomic) NSString* fileSN;
@property (strong,nonatomic) NSString* version;
@property (strong,nonatomic) NSString* dependVer;
@property (strong,nonatomic) NSString* verFlag;
@property (strong,nonatomic) NSString* year;
@property (strong,nonatomic) NSString* month;
@property (strong,nonatomic) NSString* day;

// This group of members represents additional info about files already on terminal.

@property (strong,nonatomic) NSString* customerId;
@property (strong,nonatomic) NSString* compatibilityMatrix;

- (id)initWithUNSFile:(LDTmsFileVersionInfo*)ldtFileversionInfo;
- (id)initWithUNSJson:(NSString*)UNSJson;
- (id)init:(NSString*)infoFromReadVersion ;
- (NSString *)toString;
- (BOOL)namePortionMatches:(RUAFileVersionInfo *)info;
/**
 * Returns 1 if this object's versioning members are newer,
 * 0 if the same, -1 if older than the ones of the object passed in..
 */
- (int)compareWith:(RUAFileVersionInfo *)info;

@end
