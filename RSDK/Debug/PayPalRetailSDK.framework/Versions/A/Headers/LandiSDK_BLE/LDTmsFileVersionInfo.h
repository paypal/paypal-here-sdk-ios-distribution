//
//  LDTmsInfo.h
//  MPOSCommunicationManager
//
//  Created by Wu Robert on 1/14/15.
//  Copyright (c) 2015 Landi 联迪. All rights reserved.
//

#ifndef MPOSCommunicationManager_LDTmsInfo_h
#define MPOSCommunicationManager_LDTmsInfo_h

@interface LDTmsFileVersionInfo : NSObject

// 16bytes version identification
@property (strong,nonatomic) NSString* Platform;
@property (strong,nonatomic) NSString* SubPlatform;
@property (strong,nonatomic) NSString* FileType;
// 32bytes version details
@property (strong,nonatomic) NSString* MaintainID;
@property (strong,nonatomic) NSString* FileLevel;
@property (strong,nonatomic) NSString* FileSN;
@property (strong,nonatomic) NSString* VersionNum;
@property (strong,nonatomic) NSString* DependVerNum;
@property (strong,nonatomic) NSString* VersionFlag;
// 16bytes timestamp
@property (assign,nonatomic) NSUInteger Year;
@property (assign,nonatomic) NSUInteger Month;
@property (assign,nonatomic) NSUInteger Day;


@end

#endif
