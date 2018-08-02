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

@property (strong,nonatomic) NSString* HardwareType;
@property (strong,nonatomic) NSString* EmvKernelVer;
@property (strong,nonatomic) NSString* KeyVer;
@property (strong,nonatomic) NSString* PedVer;
@property (strong,nonatomic) NSArray* FileVerInfos;
@property (assign,nonatomic) ENU_PhaseType PhaseType;

@end

#endif
