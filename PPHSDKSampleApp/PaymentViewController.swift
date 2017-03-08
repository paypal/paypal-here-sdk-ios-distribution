//
//  PaymentViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 11/16/16.
//  Copyright © 2016 cowright. All rights reserved.
//

import UIKit


class PaymentViewController: UIViewController, UITabBarControllerDelegate {
    
    @IBOutlet weak var invAmount: UITextField!
    @IBOutlet weak var createInvoiceBtn: UIButton!
    @IBOutlet weak var invCreatedLabel: UILabel!
    @IBOutlet weak var createTxnBtn: UIButton!
    @IBOutlet weak var acceptTxnBtn: UIButton!
    @IBOutlet weak var refundBtn: UIButton!
    @IBOutlet weak var refundId: UITextField!
    @IBOutlet weak var successTxnId: UILabel!
    @IBOutlet weak var codeViewer: UITextView!
    
    let infoButton = UIButton(type: UIButtonType.infoLight)

    // Set up the relevant listeners, transactionContext, and Invoice.
    var listenerSignal: PPRetailCardPresentedSignal? = nil
    var completedSignal: PPRetailCompletedSignal? = nil
    var tc: PPRetailTransactionContext?
    var invoice: PPRetailInvoice?

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.delegate = self
        
        createTxnBtn.isHidden = true
        acceptTxnBtn.isHidden = true
        refundId.isHidden = true
        refundBtn.isHidden = true
        invCreatedLabel.isHidden = true
        codeViewer.isHidden = true
        codeViewer.layer.borderWidth = 0.5
        codeViewer.layer.cornerRadius = 5.0
        
        view.addSubview(infoButton)
        infoButton.addTarget(self, action: #selector(showInfo), for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(txnIdTap(sender:)))
        successTxnId.addGestureRecognizer(tap)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        infoButton.frame = CGRect(x: (createInvoiceBtn.frame.origin.x + createInvoiceBtn.frame.width + 10),
                                  y: (createInvoiceBtn.frame.midY - 11),
                                  width: 22,
                                  height: 22)
        infoButton.setTitle("createInvoice", for: .normal)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // This function intializes an invoice to be used for the transaction.  It simply takes the amount
    // from the input and utilizes a single item generic order.  For extra items or invoice settings,
    // simply modify/add them here so they are set.
    @IBAction func createInvoice(_ sender: UIButton) {
        
        successTxnId.isHidden = true
        
        // Invoice initialization takes in the currency code. However, if the currency used to init doesn't
        // match the active merchant's currency, then an error will happen at payment time. Simply using
        // userDefaults to store the merchant's currency after successful initializeMerchant, and then use
        // it when initializing the invoice.
        let tokenDefault = UserDefaults.init()
        let merchCurrency = tokenDefault.string(forKey: "MERCH_CURRENCY")
        
        guard let mInvoice = PPRetailInvoice.init(currencyCode: merchCurrency), invAmount.text != "" else {
            
            let alertController = UIAlertController(title: "Whoops!", message: "Something happened during invoice initialization", preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                print("Error during invoice init")
            }
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        let price = formatter.number(from: invAmount.text!) as! NSDecimalNumber
        
        mInvoice.addItem("My Order", quantity: 1, unitPrice: price, itemId: nil, detailId: nil)
        
        // The invoice Number is used for duplicate payment checking.  It should be unique for every
        // unique transaction attempt.  For payment resubmissions, simply use the same invoice number
        // to ensure that the invoice hasn't already been paid.
        mInvoice.number = "sdk2test\(arc4random_uniform(9999))"
        
        guard mInvoice.itemCount > 0, mInvoice.total!.intValue >= 1 else {
            let alertController = UIAlertController(title: "Whoops!", message: "Either there are no line items or the total amount is less than $1", preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                print("Error creating invoice")
            }
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        invoice = mInvoice

        invAmount.isHidden = true
        createInvoiceBtn.isHidden = true
        invCreatedLabel.isHidden = false
        createTxnBtn.isHidden = false
        invAmount.endEditing(true)
        
        infoButton.frame = CGRect(x: (createTxnBtn.frame.origin.x + createTxnBtn.frame.width + 10),
                                  y: (createTxnBtn.frame.midY - 11),
                                  width: 22,
                                  height: 22)
        infoButton.setTitle("createTxn", for: .normal)
    }
    
    // This function does the createTransaction call to start the process with the current invoice.
    @IBAction func createTransaction(_ sender: UIButton) {
        
        tc = PayPalRetailSDK.createTransaction(invoice)
        createTxnBtn.isHidden = true
        invCreatedLabel.isHidden = true
        acceptTxnBtn.isHidden = false
        
        infoButton.frame = CGRect(x: (acceptTxnBtn.frame.origin.x + acceptTxnBtn.frame.width + 10),
                                  y: (acceptTxnBtn.frame.midY - 11),
                                  width: 22,
                                  height: 22)
        infoButton.setTitle("acceptTxn", for: .normal)
        
    }
    
    // This function will activate the reader by calling the begin method of TransactionContext.  This will
    // activate the reader and have it show the payment methods available for payment.  The listeners are
    // set in this function as well to allow for the listening of the user either inserting, swiping, or tapping
    // their payment device.
    @IBAction func acceptTransaction(_ sender: UIButton) {

        tc!.begin(true)
        
        listenerSignal = tc!.addCardPresentedListener({ (cardInfo) -> Void in
            self.tc!.continue(with: cardInfo)
        }) as PPRetailCardPresentedSignal?
        
        completedSignal = tc!.addCompletedListener({ (error, txnRecord) -> Void in
            
            self.tc!.removeCardPresentedListener(self.listenerSignal)
            self.tc!.removeCompletedListener(self.completedSignal)
            
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.debugDescription)")
                print("Debug ID: \(err.debugId)")
                
                return
            }
            
            print("Txn ID: \(txnRecord!.transactionNumber!)")
            self.successTxnId.isHidden = false
            self.successTxnId.text = "Txn Id: \(txnRecord!.transactionNumber!)"
            self.successTxnId.isUserInteractionEnabled = true
            self.acceptTxnBtn.isHidden = true
            self.invCreatedLabel.isHidden = true
            self.invAmount.isHidden = false
            self.invAmount.text = ""
            self.createInvoiceBtn.isHidden = false
            
            self.infoButton.frame = CGRect(x: (self.successTxnId.frame.origin.x + self.successTxnId.frame.width + 130),
                                      y: (self.successTxnId.frame.midY - 22),
                                      width: 22,
                                      height: 22)
            self.infoButton.setTitle("tapSuccessId", for: .normal)
            
        }) as PPRetailCompletedSignal?
        
        
    }
    
    // This function will process the refund.  It will first show an alert box to determine whether
    // this is a card present/not present refund.  If it's card not present, then it will simply continue
    // with a nil card object.  If the card is present, then it will request the card and continue with
    // the card supplied.
    @IBAction func processRefund(_ sender: UIButton) {
        
        tc = PayPalRetailSDK.createTransaction(invoice)
        
        let alertController = UIAlertController(title: "Refund $\(tc!.invoice!.total!)", message: "Is the card present?", preferredStyle: UIAlertControllerStyle.alert)
        let cardNotPresent = UIAlertAction(title: "No", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            self.tc!.beginRefund(false, amount: self.invoice?.total)
            self.tc!.continue(with: nil)
        }
        
        let cardPresent = UIAlertAction(title: "Yes", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
            self.tc!.beginRefund(true, amount: self.invoice?.total)
        }
        
        alertController.addAction(cardNotPresent)
        alertController.addAction(cardPresent)
        self.present(alertController, animated: true, completion: nil)
        
        
        listenerSignal = tc!.addCardPresentedListener({ (cardInfo) -> Void in
            self.tc!.continue(with: cardInfo)
        }) as PPRetailCardPresentedSignal?
        
        completedSignal = tc!.addCompletedListener({ (error, txnRecord) -> Void in
            
            self.tc!.removeCardPresentedListener(self.listenerSignal)
            self.tc!.removeCompletedListener(self.completedSignal)
            
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.debugDescription)")
                print("Debug ID: \(err.debugId)")
                
                return
            }
            
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
            
            self.infoButton.frame = CGRect(x: (self.createInvoiceBtn.frame.origin.x + self.createInvoiceBtn.frame.width + 10),
                                      y: (self.createInvoiceBtn.frame.midY - 11),
                                      width: 22,
                                      height: 22)
            self.infoButton.setTitle("createInvoice", for: .normal)

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
        
        infoButton.frame = CGRect(x: (refundBtn.frame.origin.x + refundBtn.frame.width + 10),
                                  y: (refundBtn.frame.midY - 11),
                                  width: 22,
                                  height: 22)
        infoButton.setTitle("refundButton", for: .normal)
        
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        
        // If the Initialize & Merchant tab is selected, I'm cancelling the current transaction so that it
        // can be restarted when entering the payments tab again. This prevents a scenario where one merchant
        // account is used to start the transaction but then they logout and login with a different merchant
        // prior to processing the transaction.
        if (tabBarController.selectedIndex == 0) {
            tc?.cancel()
            invAmount.isHidden = false
            invAmount.text = ""
            createInvoiceBtn.isHidden = false
            createTxnBtn.isHidden = true
            acceptTxnBtn.isHidden = true
            refundId.isHidden = true
            refundBtn.isHidden = true
            invCreatedLabel.isHidden = true
        }
        
    }
    
    @IBAction func showInfo(_ sender: UIButton){
        
        guard let btnTitle = sender.currentTitle else {
            print("button title wasn't set for some reason")
            return
        }

        switch btnTitle {
        case "createInvoice":
            if (codeViewer.isHidden) {
                codeViewer.isHidden = false
                codeViewer.text = "\nmInvoice = PPRetailInvoice.init(currencyCode: \"USD\")"
            } else {
                codeViewer.isHidden = true
            }
        case "createTxn":
            if (codeViewer.isHidden) {
                codeViewer.isHidden = false
                codeViewer.text = "\ntc = PayPalRetailSDK.createTransaction(invoice: PPRetailInvoice!)"
            } else {
                codeViewer.isHidden = true
            }
        case "acceptTxn":
            if (codeViewer.isHidden) {
                codeViewer.isHidden = false
                codeViewer.text = "\ntc.begin(showPrompt: Bool)"
            } else {
                codeViewer.isHidden = true
            }
        case "tapSuccessId":
            if (codeViewer.isHidden) {
                codeViewer.isHidden = false
                codeViewer.text = "\nTouch the transaction ID to initiate the refund flow for that transaction."
            } else {
                codeViewer.isHidden = true
            }
        case "refundButton":
            if (codeViewer.isHidden) {
                codeViewer.isHidden = false
                codeViewer.text = "\ntc.beginRefund(cardPresent: Bool, amount: NSDecimalNumber)"
            } else {
                codeViewer.isHidden = true
            }
        default:
            print("No Button Title Found")
        }
        
    }
    
}

