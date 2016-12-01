//
//  PaymentViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 11/16/16.
//  Copyright © 2016 cowright. All rights reserved.
//

import UIKit


class PaymentViewController: UIViewController {
    
    @IBOutlet weak var invAmount: UITextField!
    @IBOutlet weak var createInvoiceBtn: UIButton!
    @IBOutlet weak var invCreatedLabel: UILabel!
    @IBOutlet weak var createTxnBtn: UIButton!
    @IBOutlet weak var acceptTxnBtn: UIButton!
    @IBOutlet weak var refundBtn: UIButton!
    @IBOutlet weak var refundId: UITextField!
    @IBOutlet weak var successTxnId: UILabel!
    

    // Set up the relevant listeners, transactionContext, and Invoice.
    var listenerSignal: PPRetailCardPresentedSignal? = nil
    var completedSignal: PPRetailCompletedSignal? = nil
    var tm: PPRetailTransactionContext?
    var invoice: PPRetailInvoice?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        createTxnBtn.isHidden = true
        acceptTxnBtn.isHidden = true
        refundId.isHidden = true
        refundBtn.isHidden = true
        invCreatedLabel.isHidden = true

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // This function intializes an invoice to be used for the transaction.  It simply takes the amount
    // from the input and utilizes a single item generic order.  For extra items or invoice settings,
    // simply modify/add them here so they are set.
    @IBAction func createInvoice(_ sender: UIButton) {
        
        invoice = PPRetailInvoice.init(currencyCode: "USD")
        
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        let price = formatter.number(from: invAmount.text!) as! NSDecimalNumber
        
        invoice!.addItem("My Order", quantity: 1, unitPrice: price, itemId: nil, detailId: nil)
        
        // The invoice Number is used for duplicate payment checking.  It should be unique for every
        // unique transaction attempt.  For payment resubmissions, simply use the same invoice number
        // to ensure that the invoice hasn't already been paid.
        //
        // invoice!.number = "sdk2test001"

        if(invoice!.itemCount > 0) {
            invAmount.isHidden = true
            createInvoiceBtn.isHidden = true
            invCreatedLabel.isHidden = false
            createTxnBtn.isHidden = false
            invAmount.endEditing(true)
        } else {
            print("Error creating invoice for some reason :(")
        }
        
    }
    
    // This function does the createTransaction call to start the process with the current invoice.
    @IBAction func createTransaction(_ sender: UIButton) {
        
        tm = PayPalRetailSDK.createTransaction(invoice)
        createTxnBtn.isHidden = true
        invCreatedLabel.isHidden = true
        acceptTxnBtn.isHidden = false
        
    }
    
    // This function will activate the reader by calling the begin method of TransactionContext.  This will
    // activate the reader and have it show the payment methods available for payment.  The listeners are
    // set in this function as well to allow for the listening of the user either inserting, swiping, or tapping
    // their payment device.
    @IBAction func acceptTransaction(_ sender: UIButton) {
        
        tm!.begin(true)
        
        listenerSignal = tm!.addCardPresentedListener({ (cardInfo) -> Void in
            self.tm!.continue(with: cardInfo)
        }) as PPRetailCardPresentedSignal?
        
        completedSignal = tm!.addCompletedListener({ (error, txnRecord) -> Void in
            if((error) != nil) {
                print("Error Code: \(error!.code)")
                print("Error Message: \(error!.debugDescription)")
                print("Debug ID: \(error!.debugId)")
            } else {
                print("Txn ID: \(txnRecord!.transactionNumber!)")
                self.successTxnId.text = "Txn Id: \(txnRecord!.transactionNumber!)"
                self.successTxnId.adjustsFontSizeToFitWidth = true
                self.successTxnId.textAlignment = .center
                self.acceptTxnBtn.isHidden = true
                self.invCreatedLabel.isHidden = true
                self.invAmount.isHidden = false
                self.invAmount.text = ""
                self.createInvoiceBtn.isHidden = false
            }
            self.tm!.removeCardPresentedListener(self.listenerSignal)
            self.tm!.removeCompletedListener(self.completedSignal)
            
        }) as PPRetailCompletedSignal?
        
    }
    
    
    @IBAction func processRefund(_ sender: UIButton) {
        
        // currently the text box and button are hidden due to no way to look up the invoice based off of ID

        
    }
    
    
    
    
    
    
    
}

