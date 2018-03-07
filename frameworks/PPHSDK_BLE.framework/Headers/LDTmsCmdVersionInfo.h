//
//  LDTmsCmdVersionInfo.h
//  MPOSCommunicationManager
//
//  Created by Wu Robert on 1/14/15.
//  Copyright (c) 2015 Landi 联迪. All rights reserved.
//

#ifndef MPOSCommunicationManager_LDTmsCmdVersionInfo_h
#define MPOSCommunicationManager_LDTmsCmdVersionInfo_h

#import "LDTmsFileVersionInfo.h"

typedef enum _tagPhaseType{
    PHASE_UNKNOW = 0,
    PHASE_1 = 1,
    PHASE_2 = 2,
}ENU_PhaseType;

@interface LDTmsCmdVersionInfo : NSObject

@property (nonatomic, strong) NSString *HardwareType;
@property (nonatomic, strong) NSString *EmvKernelVer;
@property (nonatomic, strong) NSString *KeyVer;
@property (nonatomic, strong) NSString *PedVer;
@property (nonatomic, strong) NSArray *FileVerInfos;
@property (nonatomic, assign) ENU_PhaseType PhaseType;

@end

#endif
