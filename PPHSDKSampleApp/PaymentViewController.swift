//
//  PaymentViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 11/16/16.
//  Copyright © 2016 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class PaymentViewController: UIViewController {
    
    @IBOutlet weak var demoAppLbl: UILabel!
    @IBOutlet weak var invAmount: UITextField!
    @IBOutlet weak var createInvoiceBtn: UIButton!
    @IBOutlet weak var createInvCodeBtn: UIButton!
    @IBOutlet weak var createInvCodeView: UITextView!
    @IBOutlet weak var createTxnBtn: UIButton!
    @IBOutlet weak var createTxnCodeBtn: UIButton!
    @IBOutlet weak var createTxnCodeView: UITextView!
    @IBOutlet weak var acceptTxnBtn: UIButton!
    @IBOutlet weak var acceptTxnCodeBtn: UIButton!
    @IBOutlet weak var acceptTxnCodeView: UITextView!
    @IBOutlet weak var refundBtn: UIButton!
    @IBOutlet weak var refundId: UITextField!
    @IBOutlet weak var successTxnId: UILabel!
    @IBOutlet weak var codeViewer: UITextView!
    @IBOutlet weak var backToInitPgBtn: UIButton!
    @IBOutlet weak var txnCompletedView: UIView!
    @IBOutlet weak var successMsg: UILabel!
    @IBOutlet weak var txnInfoView: UIView!
    @IBOutlet weak var refundTxnCodeView: UITextView!
    @IBOutlet weak var refundCodeBtn: UIButton!
    @IBOutlet weak var noRefundBtn: UIButton!
    @IBOutlet weak var wantToRefundLbl: UILabel!
    @IBOutlet weak var concludeFlowLbl: UILabel!

    // Set up the transactionContext and invoice params.
    var tc: PPRetailTransactionContext?
    var invoice: PPRetailInvoice?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting up initial aesthetics.
        demoAppLbl.font = UIFont.boldSystemFont(ofSize: 16.0)
        
        invAmount.layer.borderColor = (UIColor(red: 0/255, green: 159/255, blue: 228/255, alpha: 1)).cgColor
        invAmount.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let window = UIApplication.shared.keyWindow
        window!.rootViewController = self
        
        invAmount.becomeFirstResponder()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // This function intializes an invoice to be used for the transaction.  It simply takes the amount
    // from the input and utilizes a single item generic order.  For extra items or invoice settings,
    // simply modify/add them here so they are set.
    @IBAction func createInvoice(_ sender: UIButton) {
        
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
        let price = formatter.number(from: invAmount.text!.replacingOccurrences(of: "$", with: "")) as! NSDecimalNumber

        mInvoice.addItem("My Order", quantity: 1, unitPrice: price, itemId: 123, detailId: nil)
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

        invAmount.isEnabled = false
        createInvoiceBtn.isEnabled = false
        createInvoiceBtn.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .normal)
        
        createTxnCodeBtn.isEnabled = true
        createTxnBtn.isEnabled = true
        
    }
    
    // This function does the createTransaction call to start the process with the current invoice.
    @IBAction func createTransaction(_ sender: UIButton) {
        
        tc = PayPalRetailSDK.createTransaction(invoice)
        
        createTxnBtn.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .normal)
        createTxnBtn.isEnabled = false
        
        acceptTxnCodeBtn.isEnabled = true
        acceptTxnBtn.isEnabled = true
        
    }
    
    // This function will activate the reader by calling the begin method of TransactionContext.  This will
    // activate the reader and have it show the payment methods available for payment.  The listeners are
    // set in this function as well to allow for the listening of the user either inserting, swiping, or tapping
    // their payment device.
    @IBAction func acceptTransaction(_ sender: UIButton) {
        
        tc!.begin()
        
        tc!.setCardPresentedHandler { (cardInfo) -> Void in
            self.tc!.continue(with: cardInfo)
        }
        
        tc!.setCompletedHandler { (error, txnRecord) -> Void in
            
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.message)")
                print("Debug ID: \(err.debugId)")
                
                return
            }
            
            print("Txn ID: \(txnRecord!.transactionNumber!)")
            self.backToInitPgBtn.isHidden = true
            self.txnCompletedView.isHidden = false
            self.successTxnId.text = txnRecord!.transactionNumber!
            self.successTxnId.sizeToFit()
            self.successMsg.text = "Your payment of $\(self.tc!.invoice!.total!) was successful"
            self.successMsg.sizeToFit()
            self.concludeFlowLbl.isHidden = true
        }

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
        
        
        tc!.setCardPresentedHandler({ (cardInfo) -> Void in
            self.tc!.continue(with: cardInfo)
        })
        
        tc!.setCompletedHandler({ (error, txnRecord) -> Void in
            
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.message)")
                print("Debug ID: \(err.debugId)")
                
                return
            }
            
            print("Refund ID: \(txnRecord!.transactionNumber!)")
            self.backToInitPgBtn.isHidden = false
            self.backToInitPgBtn.setTitle("Start Over", for: .normal)
            self.successMsg.text = "Your refund of $\(self.tc!.invoice!.total!) was successful"
            self.wantToRefundLbl.isHidden = true
            self.concludeFlowLbl.isHidden = false
            self.txnInfoView.isHidden = true
            self.noRefundBtn.isHidden = true
            

        })
        
        
    }
    
    
    // If the 'go back to initial setup' button is selected, I'm cancelling the current transaction so that it
    // can be restarted when entering the payments tab again. This prevents a scenario where one merchant
    // account is used to start the transaction but then they logout and login with a different merchant
    // prior to processing the transaction.
    @IBAction func backToInitPage(_ sender: Any) {
        
        if ((tc) != nil) {
            tc?.clear({ (error) in
                if let err = error {
                    print("Error Code: \(err.code)")
                    print("Error Message: \(err.developerMessage)")
                    print("Debug ID: \(err.debugId)")
                    
                    return
                }
            })
        }
        
        dismiss(animated: true, completion: nil)
        
    }
    
    
    @IBAction func showInfo(_ sender: UIButton){

        switch sender.tag {
        case 0:
            if (createInvCodeView.isHidden) {
                createInvCodeBtn.setTitle("Hide Code", for: .normal)
                createInvCodeView.isHidden = false
                createInvCodeView.text = "mInvoice = PPRetailInvoice.init(currencyCode: \"USD\")"
            } else {
                createInvCodeBtn.setTitle("View Code", for: .normal)
                createInvCodeView.isHidden = true
            }
        case 1:
            if (createTxnCodeView.isHidden) {
                createTxnCodeBtn.setTitle("Hide Code", for: .normal)
                createTxnCodeView.isHidden = false
                createTxnCodeView.text = "tc = PayPalRetailSDK.createTransaction(invoice)"
            } else {
                createTxnCodeBtn.setTitle("View Code", for: .normal)
                createTxnCodeView.isHidden = true
            }
        case 2:
            if (acceptTxnCodeView.isHidden) {
                acceptTxnCodeBtn.setTitle("Hide Code", for: .normal)
                acceptTxnCodeView.isHidden = false
                acceptTxnCodeView.text = "tc.begin()"
            } else {
                acceptTxnCodeBtn.setTitle("View Code", for: .normal)
                acceptTxnCodeView.isHidden = true
            }
        case 3:
            if (refundTxnCodeView.isHidden) {
                refundCodeBtn.setTitle("Hide Code", for: .normal)
                refundTxnCodeView.isHidden = false
                refundTxnCodeView.text = "tc.beginRefund(cardPresent: Bool, amount: NSDecimalNumber)"
            } else {
                refundCodeBtn.setTitle("View Code", for: .normal)
                refundTxnCodeView.isHidden = true
            }
        default:
            print("No Button Tag Found")
        }
        
    }
    
    // Function to handle real-time changes in the invoice/payment amount text field.  The
    // create invoice button is disabled unless there is a value in the box.
    func editingChanged(_ textField: UITextField) {

        if let amountString = textField.text?.currencyInputFormatting() {
            textField.text = amountString
        }
        
        guard let amt = invAmount.text, !amt.isEmpty else {
            createInvoiceBtn.isEnabled = false
            createInvCodeBtn.isEnabled = false
            return
        }
        
        createInvoiceBtn.isEnabled = true
        createInvCodeBtn.isEnabled = true
        
    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }
    
}

extension String {
    
    // Formatting for invoice amount text field
    func currencyInputFormatting() -> String {
        
        var number: NSDecimalNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        var amountWithPrefix = self
        
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue
        number = NSDecimalNumber(value: (double / 100))

        guard number != 0 as NSDecimalNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
}

