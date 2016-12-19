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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(txnIdTap(sender:)))
        successTxnId.addGestureRecognizer(tap)

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
        invoice!.number = "sdk2test\(arc4random_uniform(9999))"

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
                self.successTxnId.isUserInteractionEnabled = true
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
    
    // This function will process the refund.  It will first show an alert box to determine whether
    // this is a card present/not present refund.  If it's card not present, then it will simply continue
    // with a nil card object.  If the card is present, then it will request the card and continue with
    // the card supplied.
    @IBAction func processRefund(_ sender: UIButton) {
        
        tm = PayPalRetailSDK.createTransaction(invoice)
        
        let alertController = UIAlertController(title: "Refund $\(tm!.invoice!.total!)", message: "Is the card present?", preferredStyle: UIAlertControllerStyle.alert)
        let cardNotPresent = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            self.tm!.beginRefund(false, amount: self.invoice?.total)
            self.tm!.continue(with: nil)
        }
        
        let cardPresent = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            self.tm!.beginRefund(true, amount: self.invoice?.total)
        }
        
        alertController.addAction(cardNotPresent)
        alertController.addAction(cardPresent)
        self.present(alertController, animated: true, completion: nil)
        
        
        listenerSignal = tm!.addCardPresentedListener({ (cardInfo) -> Void in
            self.tm!.continue(with: cardInfo)
        }) as PPRetailCardPresentedSignal?
        
        completedSignal = tm!.addCompletedListener({ (error, txnRecord) -> Void in
            if((error) != nil) {
                print("Error Code: \(error!.code)")
                print("Error Message: \(error!.debugDescription)")
                print("Debug ID: \(error!.debugId)")
            } else {
                print("Refund ID: \(txnRecord!.transactionNumber!)")
                self.successTxnId.text = "Refund Id: \(txnRecord!.transactionNumber!)"
                self.successTxnId.adjustsFontSizeToFitWidth = true
                self.successTxnId.textAlignment = .center
                self.successTxnId.isUserInteractionEnabled = false
                self.successTxnId.isHidden = false
                self.invAmount.isHidden = false
                self.invAmount.text = ""
                self.createInvoiceBtn.isHidden = false
                self.refundId.isHidden = true
                self.refundBtn.isHidden = true
            }
            self.tm!.removeCardPresentedListener(self.listenerSignal)
            self.tm!.removeCompletedListener(self.completedSignal)
            
        }) as PPRetailCompletedSignal?
        
    }
    
    // This function enables tap functionality on the successful transaction ID so that a refund
    // is triggered.  When a transaction completes, the user can click the transaction ID to initiate
    // a refund.  By tapping the transaction ID, the app will populate the refund ID text box with the
    // transaction ID and show that along with the refund button.  This functionality is disabled for 
    // refund transaction IDs as you can't refund from a refund ID.
    func txnIdTap(sender:UITapGestureRecognizer) {
        
        invAmount.isHidden = true
        createInvoiceBtn.isHidden = true
        successTxnId.isHidden = true
        refundId.isHidden = false
        refundId.text = successTxnId.text!.replacingOccurrences(of: "Txn Id: ", with: "")
        refundBtn.isHidden = false
    }
    
    
    
    
}

