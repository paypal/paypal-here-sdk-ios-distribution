//
//  PPHReaderConstants.h
//  PayPalHereSDK
//
//  Created by Pavlinsky, Matthew on 2/17/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#ifndef PayPalHereSDK_PPHReaderConstants_h
#define PayPalHereSDK_PPHReaderConstants_h

typedef NS_ENUM(NSInteger, PPHReaderType) {
    ePPHReaderTypeUnknown,
    ePPHReaderTypeAudioJack,
    ePPHReaderTypeDockPort,
    ePPHReaderTypeChipAndPinBluetooth
};

typedef NS_OPTIONS(NSInteger, PPHReaderTypeMask) {
    ePPHReaderTypeMaskNone = 0,
    ePPHReaderTypeMaskAudioJack = 1 << ePPHReaderTypeAudioJack,
    ePPHReaderTypeMaskDockPort = 1 << ePPHReaderTypeDockPort,
    ePPHReaderTypeMaskChipAndPinBluetooth = 1 << ePPHReaderTypeChipAndPinBluetooth,
    ePPHReaderTypeMaskAll = ePPHReaderTypeMaskAudioJack | ePPHReaderTypeMaskDockPort |
    ePPHReaderTypeMaskChipAndPinBluetooth
};

typedef NS_ENUM(NSInteger, PPHReaderModel) {
    ePPHReaderModelUnknown,
    ePPHReaderModelMiuraM000,
    ePPHReaderModelMiuraM003,
    ePPHReaderModelMiuraM010,
    ePPHReaderModelMagtekAudio,
    ePPHReaderModelRoamAudio,
    ePPHReaderModelMagtekiDynamo,
};

@interface PPHReaderConstants : NSObject

+ (PPHReaderModel)readerModelFromModelString:(NSString*)modelString;
+ (PPHReaderType)readerTypeFromModel:(PPHReaderModel)model;

+ (NSString *)stringForReaderType:(PPHReaderType)type;

@end

#endif
