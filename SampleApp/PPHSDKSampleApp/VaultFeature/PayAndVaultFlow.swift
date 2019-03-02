//
//  PayAndVaultFlow.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/14/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK


class PayAndVaultFlow: NSObject {
    
    /*
    Below are the steps to process Pay & Vault transactions. The only step not outlined here
    is the login with Braintree that is initiated from the VaultPaymentViewController.
    Merchant needs to login first to allow access and capture token. Then procced with the steps below for vaulting.
    This object only exists to abstract away the sdk related code from the model and views to demonstrate basic sdk to follow.
    */

    // MARK: - Vault and Pay. High Level Flow
    class func submitPayAndVaultTransactionWithPayPalHereSDK(trxModel: VaultTransactionModel, payAndVaultCompletion: @escaping (VaultTransactionModel) -> Void) {
        
        // 1. Create Invoice
        createInvoice(trxModel) { (invoiceErrMsg) in
            guard invoiceErrMsg == nil else {
                trxModel.errorMsg = invoiceErrMsg
                payAndVaultCompletion(trxModel)
                return
            }
            
            // 2. Create Transaction Context with invoice
            self.createTransactionContext(invoice: trxModel.invoice!) { (tcErrMsg, context) in
                guard tcErrMsg == nil else {
                    trxModel.errorMsg = tcErrMsg
                    payAndVaultCompletion(trxModel)
                    return
                }
                
                // 3. Accept transaction and begin payment with options
                self.acceptTransaction(tc: context!, trxModel: trxModel) { (paymentErr) in
                    guard paymentErr == nil else {
                        trxModel.errorMsg = paymentErr
                        payAndVaultCompletion(trxModel)
                        return
                    }
                    
                    // Successfully completed transaction!
                    payAndVaultCompletion(trxModel)
                }
            }
        }
    }
    
    
    // MARK: - Pay and Vault Method Details
    // MARK: 1. Create invoice
    // This function intializes an generic one item invoice with the amount entered to be used for the demo transaction.
    // For extra items or invoice settings, simply modify/add them here so they are set.
    fileprivate class func createInvoice(_ trxModel: VaultTransactionModel, invoiceCompletion: @escaping (ErrorMsg?) -> Void) {
        
        // Invoice initialization requires a currency code. However, if the currency used to initialize
        // invoice doesn't match the active merchant's currency, then an error will happen at payment time.
        // Here we retreive merchant's currency from UserDefaults. It was stored there earlier in the AppDelegate
        // with succefull merchant initialization.
        let tokenDefault = UserDefaults()
        let merchCurrency = tokenDefault.string(forKey: "MERCH_CURRENCY")
        
        guard let merchInvoice = PPRetailInvoice.init(currencyCode: merchCurrency) else {
            invoiceCompletion(ErrorMsg(title: "Invoice initialization failed", message: "Something happened during invoice initialization"))
            return
        }
        
        // Checks for amount input parameter
        guard let amount = trxModel.amountString, amount != "" else {
            invoiceCompletion(ErrorMsg(title: "Amount must be $1.00 or greater", message: "In createInvoice()"))
            return
        }
        
        let price = trxModel.nsDecimalAmount()
        
        merchInvoice.addItem("My Order", quantity: 1, unitPrice: price, itemId: 123, detailId: nil)
        
        // The invoice Number is used for duplicate payment checking.  It should be unique for every
        // unique transaction attempt.  For payment resubmissions, simply use the same invoice number
        // to ensure that the invoice hasn't already been paid. For sample purposes, this app is
        // simply generating a random number to append to the string 'sdk2test'.
        merchInvoice.number = "sdk2test\(arc4random_uniform(99999))"
        
        guard merchInvoice.itemCount > 0, merchInvoice.total!.intValue >= 1 else {
            invoiceCompletion(ErrorMsg(title: "Must have line items and total amount > $0.99", message: "Either no line items or the total amount is less than \(trxModel.currencySymbol)1"))
            return
        }
    
        // Attach invoice to vault transaction model
        trxModel.invoice = merchInvoice
        
        invoiceCompletion(nil)
    }
    
    
    // MARK: 2. Create transacrion context
    fileprivate class func createTransactionContext(invoice: PPRetailInvoice, transactionCompetion: @escaping (ErrorMsg?, PPRetailTransactionContext?) -> Void) {
        PayPalRetailSDK.transactionManager()?.createTransaction(invoice, callback: { (error, context) in
            if error != nil {
                transactionCompetion(ErrorMsg(title: "Transaction context failed", message: "Error initializing transaction context"), nil)
                return
            }
            transactionCompetion(nil, context!)
        })
    }
    
    
    // MARK: 3. Set completed handlers and begin payment
    // This function will activate the reader by calling the begin method of TransactionContext.  This will
    // activate the reader and have it show the payment methods available for payment.  The listeners are
    // set in this function as well to allow for the listening of the user either inserting, swiping, or tapping
    // their payment device.
    fileprivate class func acceptTransaction(tc: PPRetailTransactionContext, trxModel: VaultTransactionModel, acceptCompletion: @escaping(ErrorMsg?) -> Void) {
        
        // This card presented listener is optional as the SDK will automatically continue when the card is
        // presented even if this listener is not implemented.
        tc.setCardPresentedHandler { (cardInfo) -> Void in
            tc.continue(with: cardInfo)
        }
        
        // Transaction completion handler is called SECOND, after the vault completed handler below.
        // Error is returned if transaction cancelled on screen by user.
        tc.setCompletedHandler { (error, txnRecord) -> Void in
            if error != nil {
                acceptCompletion(ErrorMsg(title: "Transaction failed", message: "Error in transaction completion handler: \(error?.message ?? "") or user cancelled."))
                return
            } else {
                print("Txn ID: \(txnRecord!.transactionNumber!)")
                
                // Set transaction record on model
                trxModel.transactionRecord = txnRecord
                
                // Payment and Vault have succeeded!
                acceptCompletion(nil)
            }
        }
        
        // Vault completion handler is called FIRST, before transaction copmleted handler to receive vaultId
        // and vaultValidUntil property.
        tc.setVaultCompletedHandler({ (error, vaultRecord) in
            if error != nil {
                acceptCompletion(ErrorMsg(title: "Vault failed", message: "Error in vault completion handler: \(error?.message ?? "")"))
            } else {
                print("Vault ID: \(vaultRecord?.vaultId ?? "No Vault ID!"))")
                
                // Set vault info on model
                trxModel.vaultRecord = vaultRecord!
            }
        })
        
        tc.beginPayment(trxModel.options)
    }
    
}

