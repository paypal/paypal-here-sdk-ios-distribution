//
//  
//  PayPalHereSDK
//
//  Created by Curam, Abhay on 1/7/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

typedef NS_ENUM(NSInteger, PPHSupportedPaymentInterface) {
    ePPHSupportedPaymentInterfaceUnknown,
    ePPHSupportedPaymentInterfaceContactlessMagStripe,
    ePPHSupportedPaymentInterfaceContactlessEMVChipAndPin,
    ePPHSupportedPaymentInterfaceEMVChipAndPin,
    ePPHSupportedPaymentInterfaceSwipe
};

typedef NS_OPTIONS(NSInteger, PPHSupportedPaymentInterfaceMask) {
    ePPHSupportedPaymentInterfaceMaskNone = 0,
    ePPHSupportedPaymentInterfaceMaskContactlessMagStripe = 1 << ePPHSupportedPaymentInterfaceContactlessMagStripe,
    ePPHSupportedPaymentInterfaceMaskContactlessEMVChipAndPin = 1 << ePPHSupportedPaymentInterfaceContactlessEMVChipAndPin,
    ePPHSupportedPaymentInterfaceMaskEMVChipAndPin = 1 << ePPHSupportedPaymentInterfaceEMVChipAndPin,
    ePPHSupportedPaymentInterfaceMaskSwipe = 1 << ePPHSupportedPaymentInterfaceSwipe,
    ePPHSupportedPaymentInterfaceMaskAll =
        ePPHSupportedPaymentInterfaceMaskContactlessMagStripe |
        ePPHSupportedPaymentInterfaceMaskContactlessEMVChipAndPin |
        ePPHSupportedPaymentInterfaceMaskEMVChipAndPin |
        ePPHSupportedPaymentInterfaceMaskSwipe
};
