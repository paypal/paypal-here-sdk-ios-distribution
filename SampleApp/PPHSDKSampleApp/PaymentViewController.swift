//
//  PaymentViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 11/16/16.
//  Copyright © 2016 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class PaymentViewController: UIViewController, PPHRetailSDKAppDelegate {
    
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
    @IBOutlet weak var pmtTypeSelector: UISegmentedControl!
    @IBOutlet weak var optionsTextFeild: UITextField!
    
    // Set up the transactionContext and invoice params.
    var tc: PPRetailTransactionContext?
    var invoice: PPRetailInvoice?
    var transactionNumber: String?
    var paymentMethod: PPRetailInvoicePaymentMethod?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        PayPalRetailSDK.setRetailSDKAppDelegate(self)
        
        //init toolbar for keyboard
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(CaptureAuthViewController.doneButtonAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.invAmount.inputAccessoryView = toolbar
        self.optionsTextFeild.inputAccessoryView = toolbar
        
        // Setting up initial aesthetics.
        invAmount.layer.borderColor = (UIColor(red: 0/255, green: 159/255, blue: 228/255, alpha: 1)).cgColor
        invAmount.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        
        optionsTextFeild.layer.borderColor = (UIColor(red: 0/255, green: 159/255, blue: 228/255, alpha: 1)).cgColor
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
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
        // to ensure that the invoice hasn't already been paid. For sample purposes, this app is
        // simply generating a random number to append to the string 'sdk2test'.
        mInvoice.number = "sdk2test\(arc4random_uniform(99999))"
        
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
        createInvoiceBtn.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .disabled)

        createTxnBtn.isEnabled = true
        
    }
    
    // This function does the createTransaction call to start the process with the current invoice.
    @IBAction func createTransaction(_ sender: UIButton) {
        
        PayPalRetailSDK.transactionManager()?.createTransaction(invoice, callback: { (error, context) in
            self.tc = context

            self.createTxnBtn.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .disabled)
            self.createTxnBtn.isEnabled = false
            
            self.acceptTxnBtn.isEnabled = true
        })
    }
    
    // This function will activate the reader by calling the begin method of TransactionContext.  This will
    // activate the reader and have it show the payment methods available for payment.  The listeners are
    // set in this function as well to allow for the listening of the user either inserting, swiping, or tapping
    // their payment device.
    @IBAction func acceptTransaction(_ sender: UIButton) {
        
        // This card presented listener is optional as the SDK will automatically continue when the card is
        // presented even if this listener is not implemented.
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
            
            self.navigationController?.popToViewController(self, animated: false)
            self.transactionNumber = txnRecord?.transactionNumber
            self.paymentMethod = txnRecord?.paymentMethod
            
            if(self.pmtTypeSelector.titleForSegment(at: self.pmtTypeSelector.selectedSegmentIndex) == "auth") {
                self.goToAuthCompletedViewController()
            } else {
                self.goToPaymentCompletedViewController()
            }
            
        }
        
        // Setting up the options for the transaction
        let options = PPRetailTransactionBeginOptions()
        options?.showPromptInCardReader = true
        options?.showPromptInApp = true
        options?.preferredFormFactors = []
        options?.tippingOnReaderEnabled = false
        options?.amountBasedTipping = false
        options?.isAuthCapture = (self.pmtTypeSelector.titleForSegment(at: self.pmtTypeSelector.selectedSegmentIndex) == "auth")
        options?.tag = optionsTextFeild.text ?? ""
        
        tc!.beginPayment(options)

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goToPmtCompletedView") {
            if let pmtCompletedViewController = segue.destination as? PaymentCompletedViewController {
                pmtCompletedViewController.transactionNumber = transactionNumber
                pmtCompletedViewController.invoice = invoice
                pmtCompletedViewController.paymentMethod = paymentMethod
            }
        }
        
        if (segue.identifier == "goToAuthCompletedView") {
            if let authCompletedViewController = segue.destination as? AuthCompletedViewController {
                authCompletedViewController.authTransactionNumber = transactionNumber
                authCompletedViewController.invoice = invoice
                authCompletedViewController.paymentMethod = paymentMethod
            }
        }
    }
    
    func goToPaymentCompletedViewController() {
        performSegue(withIdentifier: "goToPmtCompletedView", sender: Any?.self)
    }
    
    func goToAuthCompletedViewController() {
        performSegue(withIdentifier: "goToAuthCompletedView", sender: Any?.self)
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
                createTxnCodeView.text = "PayPalRetailSDK.transactionManager().createTransaction(invoice, callback: { (error, context) in \n" +
                                         "  // Set the transactionContext or handle the error \n" +
                                         "  self.tc = context \n" +
                                         "}))"
            } else {
                createTxnCodeBtn.setTitle("View Code", for: .normal)
                createTxnCodeView.isHidden = true
            }
        case 2:
            if (acceptTxnCodeView.isHidden) {
                acceptTxnCodeBtn.setTitle("Hide Code", for: .normal)
                acceptTxnCodeView.isHidden = false
                acceptTxnCodeView.text = "tc.beginPayment(options)"
            } else {
                acceptTxnCodeBtn.setTitle("View Code", for: .normal)
                acceptTxnCodeView.isHidden = true
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
            
            return
        }
        
        createInvoiceBtn.isEnabled = true
    }
    
    func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }
    
}

