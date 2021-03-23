//
//  AppStrings.swift
//  PPHSDKSampleApp
//
//  Created by Priyank Shah on 3/17/21.
//  Copyright © 2021 cowright. All rights reserved.
//

import Foundation

struct AppStrings {
    
    struct PaymentOptions {
        static let paymentTypeCardReader: String = "Card Reader"
        static let paymentTypeDigitalCard: String = "Digital Card"
        static let paymentTypeCash: String = "Cash"
        static let paymentTypeKeyIn: String = "Key in"
        static let paymentTypeCheck: String = "Check"
        static let paymentTypeQRC: String = "QRC"
    }
    
    struct ActionSheetTitles {
        static let alertControllerTitlePaymentType: String = "Choose payment type"
    }
    
    struct AlertActionTitles {
        static let alertControllerTitleCardInfo: String = "Enter Card Info"
    }
    
    struct AlertActionButtonTitles {
        static let alertActionTitleDone: String = "Done"
    }
    
    struct segueNames {
        static let paymentCompletedController = "goToPmtCompletedView"
        static let transactionOptionsVC = "transactionOptionsVC"
        static let goToPmtCompletedView = "goToPmtCompletedView"
        static let goToAuthCompletedView = "goToAuthCompletedView"
        static let offlinePaymentCompletedVC = "offlinePaymentCompletedVC"
    }
    
    struct StageEnvironment {
        struct cardDetails {
            static let stageCardNumber: String = "4111111111111111"
            static let stageCardCVV: String = "123"
            static let stageCardExpiration: String = "122030"
            static let stageCardPostalCode: String = "12345"
        }
    }
}
