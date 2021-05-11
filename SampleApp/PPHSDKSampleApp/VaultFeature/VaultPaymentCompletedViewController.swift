//
//  VaultPaymentCompletedViewController.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/14/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class VaultPaymentCompletedViewController: UIViewController {
    
    @IBOutlet weak var skipRefundButton: CustomButton!
    @IBOutlet weak var provideRefundBtn: UIButton!
    @IBOutlet weak var successMsg: UILabel!
    @IBOutlet weak var refundCodeViewer: UITextView!
    @IBOutlet weak var chooseOneLabel: UILabel!
    @IBOutlet weak var optionLabel: UILabel!
    @IBOutlet weak var separatorLabel: UILabel!
    
    var trxModel: VaultTransactionModel!

    var refundAmount: NSDecimalNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpDefaultView()
        
        if trxModel.transactionRecord?.transactionNumber == nil {
            // Vault only
            successMsg.text = "Vault successful for customer Id: " + (trxModel.options?.vaultCustomerId ?? "NO CUSTOMER ID") + "\nVaultId: \(trxModel.vaultRecord?.vaultId ?? "No Vault Id")"
            provideRefundBtn.isEnabled = false
            setVaultOnlyUI()
            skipRefundButton.setTitle("Done", for: .normal)
        }
        else {
            // Pay and Vault
            successMsg.text = "Vault for customer Id: \(trxModel.options?.vaultCustomerId ?? "NO ID") \nVault Id: \(trxModel.vaultRecord?.vaultId ?? "No Vault Id"), and \npayment of $\(trxModel.invoice?.total ?? 0.00) was successful."
            refundAmount = trxModel.invoice?.total
        }
        successMsg.sizeToFit()
    }
    
    
    
    
    // This function will process the refund. You first have to create a TransactionContext, then set the appropriate
    // listeners, and then call beginRefund. Calling beginRefund with true and the amount will first prompt
    // if there's a card available or not. Based on that selection, the refund will process for the amount
    // supplied and the completion handler will be called afterwards.
    @IBAction func provideRefund(_ sender: Any) {
        if trxModel.transactionRecord?.transactionNumber == nil { // Vault only
            alertWith(title: "No transaction to refund from vault only", message: "$1.00 amount not charged")
            return
        }
        
        PayPalRetailSDK.transactionManager()?.createRefundTransaction(trxModel.invoice?.payPalId, transactionNumber: trxModel.transactionRecord!.transactionNumber, paymentMethod: trxModel.transactionRecord!.paymentMethod, callback: refundHandler(error:tc:))
    }
    
    func refundHandler(error: PPRetailError?, tc: PPRetailTransactionContext?) {
        // This card presented listener is optional as the SDK will automatically continue if a card is
        // presented for a refund.
        tc?.setCardPresentedHandler { (cardInfo) -> Void in
            tc?.continue(with: cardInfo)
        }
        
        tc?.setCompletedHandler { (error, txnRecord) -> Void in
            
            if let err = error {
                print("Error Code: \(String(describing: err.code))")
                print("Error Message: \(String(describing: err.message))")
                print("Debug ID: \(String(describing: err.debugId))")
                
                return
            }
            print("Refund ID: \(txnRecord!.transactionNumber!)")
            
            self.skipRefund(nil)
        }
        
        tc?.beginRefund(true, amount: refundAmount)
    }
    
    
    private func setUpDefaultView(){
        refundCodeViewer.text = "tc.beginRefund(true, amount: invoice.total)"
        self.navigationController?.navigationBar.isHidden = true
    }
    
    func setVaultOnlyUI() {
        provideRefundBtn.isHidden = true
        refundCodeViewer.isHidden = true
        chooseOneLabel.isHidden = true
        optionLabel.isHidden = true
        separatorLabel.isHidden = true
    }
    
    // If the 'skipRefund' button is selected, we load a new VaultPaymentViewController
    // so that more transactions can be run.
    @IBAction func skipRefund(_ sender: UIButton?) {
        let newVaultpaymentViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "VaultPaymentViewController") as? VaultPaymentViewController
        var viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        viewControllers.removeLast()
        viewControllers[4] = newVaultpaymentViewController!
        self.navigationController?.setViewControllers(viewControllers, animated: true)
    }
    
    fileprivate func alertWith(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

}
