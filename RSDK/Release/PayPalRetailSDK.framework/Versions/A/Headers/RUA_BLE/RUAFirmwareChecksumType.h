//
//  RUAFirmwareChecksumType.h
//  ROAMreaderUnifiedAPI
//
//  Created by Mallikarjun Patil on 5/2/17.
//  Copyright © 2017 ROAM. All rights reserved.
//

#ifndef RUAFirmwareChecksumType_h
#define RUAFirmwareChecksumType_h

typedef NS_ENUM(NSInteger, RUAFirmwareChecksumType) {
    
    /**
     * Passed as parameter for getFirmwareChecksumForType() method
     * to access Static Software Version
     */
    RUAFirmwareChecksumTypeStaticSoftware = 0,
    
    /**
     * Passed as parameter for getFirmwareChecksumForType() method
     * to access Dynamic Configuration Version
     */
    RUAFirmwareChecksumTypeDynamicConfiguration = 1,
    
};

#endif /* RUAFirmwareChecksumType_h */
