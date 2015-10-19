//
//  PPHCardEnums.h
//  PayPalHereSDK
//
//  Created by Samuel Jerome on 6/26/14.
//  Copyright (c) 2014 PayPal. All rights reserved.
//

#ifndef __PPH_CARD_ENUMS_H__
#define __PPH_CARD_ENUMS_H__
typedef NS_ENUM(NSInteger, PPHCreditCardType) {
    ePPHCreditCardTypeUnknown = 0,
    ePPHCreditCardTypeVisa = 1,
    ePPHCreditCardTypeMastercard = 2,
    ePPHCreditCardTypeDiscover = 3,
    ePPHCreditCardTypeAmEx = 4,
    ePPHCreditCardTypeJCB = 5,
    ePPHCreditCardTypeMaestro = 6,
    ePPHCreditCardTypePayPal = 7
};

// The type of contactless transaction this card is attempting
typedef NS_ENUM(NSInteger, PPHContactlessTransactionType) {
    ePPHContactlessTransactionTypeUnknown = 0,
    ePPHContactlessTransactionTypeMSD,
    ePPHContactlessTransactionTypeEMV
};
#endif
