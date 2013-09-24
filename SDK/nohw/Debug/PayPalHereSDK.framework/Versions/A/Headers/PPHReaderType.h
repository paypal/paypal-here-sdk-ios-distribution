//
//  Copyright (c) 2012 PayPal. All rights reserved.
//

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
