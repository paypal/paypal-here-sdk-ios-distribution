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
@property (nonatomic, strong) NSString *Platform;
@property (nonatomic, strong) NSString *SubPlatform;
@property (nonatomic, strong) NSString *FileType;
// 32bytes version details
@property (nonatomic, strong) NSString *MaintainID;
@property (nonatomic, strong) NSString *FileLevel;
@property (nonatomic, strong) NSString *FileSN;
@property (nonatomic, strong) NSString *VersionNum;
@property (nonatomic, strong) NSString *DependVerNum;
@property (nonatomic, strong) NSString *VersionFlag;
// 16bytes timestamp
@property (nonatomic, assign) NSUInteger Year;
@property (nonatomic, assign) NSUInteger Month;
@property (nonatomic, assign) NSUInteger Day;


@end

#endif
