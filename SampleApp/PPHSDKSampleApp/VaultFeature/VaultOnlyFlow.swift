//
//  VaultOnlyFlow.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/14/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK


class VaultOnlyFlow: NSObject {
    
    /*
     Below are the steps to process a Vault Only transaction. The only step not outlined here
     is the login with Braintree that is initiated from the VaultPaymentViewController.
     Merchant first needs to login and allow access. Then procced with the steps below for vaulting.
     */
    
    class func submitVaultOnlyTransactionWithPayPalHereSDK(trxModel: VaultTransactionModel, vaultOnlyCompletion: @escaping(VaultTransactionModel) -> Void) {
        
        // MARK: 1. Create vault only specific transaction context
        PayPalRetailSDK.transactionManager()?.createVaultTransaction({ (error, vaultOnlyContext) in
            if error != nil {
                trxModel.errorMsg = ErrorMsg(title: "Vault Transaction context failed", message: "Error: \(error?.code ?? "")")
                vaultOnlyCompletion(trxModel)
                return
            }
            
            // MARK: 2. Accept transaction by setting completion handler and calling beginPayment(options)
            self.acceptVaultTransaction(tc: vaultOnlyContext!, options: trxModel.options!) { (vaultRecord, errMsg) in
                if errMsg != nil {
                    trxModel.errorMsg = errMsg
                    vaultOnlyCompletion(trxModel)
                    return
                }
                
                // Set vault record on model for future use
                trxModel.vaultRecord = vaultRecord!
                
                // Successful vault!
                vaultOnlyCompletion(trxModel)
            }
        })
    }

    // MARK: Accept vault transaction
    fileprivate class func acceptVaultTransaction(tc: PPRetailTransactionContext,  options: PPRetailTransactionBeginOptions, acceptCompletion: @escaping(PPRetailVaultRecord?, ErrorMsg?) -> Void) {
        
        // This card presented listener is optional as the SDK will automatically continue when the card is
        // presented even if this listener is not implemented.
        tc.setCardPresentedHandler { (cardInfo) -> Void in
            tc.continue(with: cardInfo)
        }
        
        // Set the vault completion handler before calling beginPayment to receive vault record with id
        // and validUntil date if successful
        tc.setVaultCompletedHandler({ (error, vaultRecord) in
            if error != nil {
                print("Error Code: \(String(describing: error?.code))")
                acceptCompletion(nil, ErrorMsg(title: "Error in vault completed handler", message: "Vault failed or user cancelled"))
            } else {
                print("Vault ID: \(vaultRecord?.vaultId ?? "No Vault ID!"))")
                acceptCompletion(vaultRecord, nil)
            }
        })
        
        tc.beginPayment(options)
    }

}
