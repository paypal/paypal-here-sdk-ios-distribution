//
//  VaultTransactionModel.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/17/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class VaultTransactionModel: NSObject {

    // MARK: - Transaction Properties
    var options = PPRetailTransactionBeginOptions.optionsForVaultPayment()
    var invoice: PPRetailRetailInvoice?
    var paymentMethod: PPRetailInvoicePaymentMethod?
    var formFactorArray: [PPRetailFormFactor] = []
    var currencySymbol = UserDefaults().value(forKey: "CURRENCY_SYMBOL") as? String ?? "$"
    var vaultRecord: PPRetailVaultRecord?
    var transactionRecord: PPRetailTransactionRecord?

    // View Exposed Properties
    var amountString: String?
    var customerId: String?
    var errorMsg: ErrorMsg?
    var segueTitle: String?

    func submitTransaction(trxResponse: @escaping (VaultTransactionModel) -> Void) {
        // Clear old error messages
        self.errorMsg = nil

        guard self.options?.vaultCustomerId != nil && self.options?.vaultCustomerId != "" else {
            self.errorMsg = ErrorMsg(title: "Customer ID is required for vault",
                                     message: "Vaulting card info requires merchant to provide customer ID")
            trxResponse(self)
            return
        }

        // Submit transaction. Files for flow objects contain detailed steps for submitting transactions
        if options?.vaultType == .vaultOnly {
            VaultOnlyFlow.submitVaultOnlyTransactionWithPayPalHereSDK(trxModel: self) { (responseTrxModel) in
                if responseTrxModel.errorMsg != nil {
                    trxResponse(self)
                    return
                }
                // Successful -> Set navigation action to execute
                self.segueTitle = "goToVaultCompletedVC"
                trxResponse(self)
            }
        } else { // .vaultAndPay
            PayAndVaultFlow.submitPayAndVaultTransactionWithPayPalHereSDK(trxModel: self) { (responseTrxModel) in
                if responseTrxModel.errorMsg != nil {
                    trxResponse(self)
                    return
                }
                // Successful -> Set navigation action to execute
                self.segueTitle = "goToVaultCompletedVC"
                trxResponse(self)
            }
        }
    }

    // Helper method
    func nsDecimalAmount() -> NSDecimalNumber? {
        guard let amntString = amountString else {
          return nil
        }
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        let trimmedString = amntString.replacingOccurrences(of: "\(currencySymbol)", with: "").replacingOccurrences(of: ",", with: "")
        return (formatter.number(from: trimmedString) as? NSDecimalNumber)
    }

}

// MARK: - Options Convenience Method
extension PPRetailTransactionBeginOptions {
    // Options can be set in different ways. Here we use a class method for convenience to initialize
    // default options for Pay & Vault.
    class func optionsForVaultPayment() -> PPRetailTransactionBeginOptions? {
        guard let options = PPRetailTransactionBeginOptions() else {return nil}
        options.showPromptInCardReader = true
        options.showPromptInApp = true
        options.preferredFormFactors = []
        options.tippingOnReaderEnabled = false
        options.amountBasedTipping = false
        options.quickChipEnabled = false
        options.isAuthCapture = false
        options.tag = ""

        // Vault specific options
        options.vaultProvider = PPRetailTransactionBeginOptionsVaultProvider.braintree
        options.vaultType = .payAndVault

        return options
    }
}
