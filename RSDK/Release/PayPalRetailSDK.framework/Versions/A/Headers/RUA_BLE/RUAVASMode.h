//
//  RUAVASMode.h
//  ROAMreaderUnifiedAPI
//
//  Created by Mallikarjun Patil on 4/19/17.
//  Copyright © 2017 ROAM. All rights reserved.
//

#ifndef RUAVASMode_h
#define RUAVASMode_h

/** @enum RUAVASMode
 Enumeration of the commands supported by RUA
 */
typedef NS_ENUM (NSInteger, RUAVASMode) {

    RUAVASModeVASOnly = 0,
    RUAVASModeDualMode = 1,
    RUAVASModePayOnly = 2,
    RUAVASModeSignUp = 3,
    RUAVASModeSingle = 4
};

#endif /* RUAVASMode_h */
