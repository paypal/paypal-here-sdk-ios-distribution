//
//  RUAFirmwareType.h
//  ROAMreaderUnifiedAPI
//
//  Created by Mallikarjun Patil on 4/27/17.
//  Copyright © 2017 ROAM. All rights reserved.
//

#ifndef RUAFirmwareType_h
#define RUAFirmwareType_h

typedef NS_ENUM(NSInteger, RUAFirmwareType) {
    
    /**
     * Passed as parameter for setFirmwareType() and getFirmwareVersionStringForType() methods
     * to access Overall Firmware Version
     */
    RUAFirmwareTypeOverallFirmware = 0,
    
    /**
     * Passed as parameter for setFirmwareType() and getFirmwareVersionStringForType() methods
     * to access Static Software Version
     */
    RUAFirmwareTypeStaticSoftware = 1,
    
    /**
     * Passed as parameter for setFirmwareType() and getFirmwareVersionStringForType() methods
     * to access Dynamic Configuration Version
     */
    RUAFirmwareTypeDynamicConfiguration = 2,
    
};

#endif /* RUAFirmwareType_h */
