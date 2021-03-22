//
//  PaymentViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 11/16/16.
//  Copyright © 2016 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

enum PaymentTypes: Int {
    case paymentTypeCardReader = 0
    case paymentTypeDigitalCard = 1
    case paymentTypeCash = 2
    case paymentTypeKeyIn = 3
    case paymentTypeCheck = 4
    case paymentTypeQRC = 5
}

class PaymentViewController: UIViewController, PPHRetailSDKAppDelegate {
    
    @IBOutlet weak var invAmount: UITextField!
    @IBOutlet weak var createInvoiceBtn: CustomButton!
    @IBOutlet weak var createInvCodeView: UITextView!
    @IBOutlet weak var createTxnBtn: CustomButton!
    @IBOutlet weak var createTxnCodeView: UITextView!
    @IBOutlet weak var acceptTxnBtn: CustomButton!
    @IBOutlet weak var acceptTxnCodeView: UITextView!
    @IBOutlet weak var offlinePaymentBtn: CustomButton!
    @IBOutlet weak var offlineModeBtn: CustomButton!
    @IBOutlet weak var btnPaymentType: UIButton!
    
    // Set up the transactionContext and invoice params.
    var tc: PPRetailTransactionContext?
    var invoice: PPRetailRetailInvoice?
    var transactionNumber: String?
    var paymentMethod: PPRetailInvoicePaymentMethod?
    var options = PPRetailTransactionBeginOptions.defaultOptions()
    var formFactorArray: [PPRetailFormFactor] = []
    var currencySymbol: String!
    var paymentType: PaymentTypes?
    let manuallyEnteredCard = PPRetailManuallyEnteredCard()
    var manuallyEnteredCardPresent: Bool = false
    
    // Get the online or offline state from the SDK by calling the "PayPalRetailSDK.transactionManager().getOfflinePaymentEnabled()"
    var offlineMode: Bool = PayPalRetailSDK.transactionManager().getOfflinePaymentEnabled()
    
    let paymentTypes: [String] = [AppStrings.PaymentOptions.paymentTypeCardReader, AppStrings.PaymentOptions.paymentTypeDigitalCard, AppStrings.PaymentOptions.paymentTypeCash, AppStrings.PaymentOptions.paymentTypeKeyIn, AppStrings.PaymentOptions.paymentTypeCheck, AppStrings.PaymentOptions.paymentTypeQRC]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpDefaultView()
        
        PayPalRetailSDK.setRetailSDKAppDelegate(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        invAmount.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpDefaultView()
        let userDefaults = UserDefaults.init()
        currencySymbol = userDefaults.value(forKey: "CURRENCY_SYMBOL") as? String ?? "$"
        invAmount.placeholder = "\(currencySymbol!) 0.00"
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
   private func getManualCard() {
    let controller = UIAlertController(title: AppStrings.AlertActionTitles.alertControllerTitleCardInfo, message: nil, preferredStyle: .alert)
    controller.addTextField { (cardNumberTextField) in
        cardNumberTextField.keyboardType = .numberPad
        cardNumberTextField.placeholder = "Enter Valid Card Number"
    }
    controller.addTextField { (cardNumberExpiryTextField) in
        cardNumberExpiryTextField.keyboardType = .numberPad
        cardNumberExpiryTextField.placeholder = "Enter Expiry Date in MMYYYY format"
    }
    controller.addTextField { (cardCVVTextField) in
        cardCVVTextField.keyboardType = .numberPad
        cardCVVTextField.isSecureTextEntry = true
        cardCVVTextField.placeholder = "Enter valid Card CVV number"
    }
    controller.addTextField { (cardPostalCodeTextField) in
        cardPostalCodeTextField.keyboardType = .numberPad
        cardPostalCodeTextField.placeholder = "Enter Postal Code"
    }

    controller.addAction(UIAlertAction(title: AppStrings.AlertActionButtonTitles.alertActionTitleDone, style: .default, handler: { (action) in
        let cardNumberTextField = controller.textFields![0]
        let cardNumberExpiryTextField = controller.textFields![1]
        let cardCVVTextField = controller.textFields![2]
        let cardPostalCodeTextField = controller.textFields![3]

        let cardNumberString = cardNumberTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        let cardNumberExpiryString = cardNumberExpiryTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).replacingOccurrences(of: "/", with: "") ?? ""
        let cardCVVString = cardCVVTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""
        let cardPostalCodeString = cardPostalCodeTextField.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) ?? ""

        if cardNumberString.count > 0 && cardNumberExpiryString.count > 0 && cardCVVString.count > 0 && cardPostalCodeString.count > 0 {
            self.manuallyEnteredCard?.setCardNumber(cardNumberString)
            self.manuallyEnteredCard?.setExpiration(cardNumberExpiryString)
            self.manuallyEnteredCard?.setCVV(cardCVVString)
            self.manuallyEnteredCard?.setPostalCode(cardPostalCodeString)
        } else {
            // Stage Card Info, Transaction Will Fail in anything but Stage
            self.manuallyEnteredCard?.setCardNumber(AppStrings.StageEnvironment.cardDetails.stageCardNumber)
            self.manuallyEnteredCard?.setCVV(AppStrings.StageEnvironment.cardDetails.stageCardCVV)
            self.manuallyEnteredCard?.setExpiration(AppStrings.StageEnvironment.cardDetails.stageCardExpiration)
            self.manuallyEnteredCard?.setPostalCode(AppStrings.StageEnvironment.cardDetails.stageCardPostalCode)
        }
        self.manuallyEnteredCardPresent = true
    }))

    self.present(controller, animated: true, completion: nil)
}
    
    //MARK:- Button Handlers
    
    @IBAction func paymentTypeHandler(_ sender: UIButton) {
       
        let actionSheetController = UIAlertController(title: AppStrings.ActionSheetTitles.alertControllerTitlePaymentType, message: nil, preferredStyle: .actionSheet)
        for (index, paymentType) in paymentTypes.enumerated() {
            let alertAction = UIAlertAction(title: paymentType, style: .default) { [self] (action) in
                if index == 0 {
                    // self.paymentTypeCardReader()
                    self.paymentType = PaymentTypes.paymentTypeCardReader
                } else if index == 1 {
                    // self.getDigitalCardCode()
                    self.paymentType = PaymentTypes.paymentTypeDigitalCard
                } else if index == 2 {
                    // self.getManualCashAmount()
                    self.paymentType = PaymentTypes.paymentTypeCash
                } else if index == 3 {
                    self.getManualCard()
                    if let pType = PPRetailTransactionBeginOptionsPaymentTypes(rawValue: PaymentTypes.paymentTypeKeyIn.rawValue) {
                        self.options?.paymentType = pType
                    }
                    self.options?.manualCard = self.manuallyEnteredCard
                } else if index == 4 {
                    // self.getManualCheckAmount()
                    self.paymentType = PaymentTypes.paymentTypeCheck
                } else if index == 5 {
                    // self.paymentTypeQRC()
                    self.paymentType = PaymentTypes.paymentTypeQRC

                self.btnPaymentType.setTitle(paymentType, for: .normal)
                }
            }
            
            if index == 3 {
                alertAction.isEnabled = true
            } else {
                alertAction.isEnabled = false
            }
            actionSheetController.addAction(alertAction)
        }
        if let popoverController = actionSheetController.popoverPresentationController {
           popoverController.sourceView = self.view //to set the source of your alert
           popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0) // you can set this as per your requirement.
           popoverController.permittedArrowDirections = [] //to hide the arrow of any particular direction
        }
        present(actionSheetController, animated: true)
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
        
        guard let mInvoice = PPRetailRetailInvoice.init(currencyCode: merchCurrency), invAmount.text != "" else {
            
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
        let price = formatter.number(from: invAmount.text!.replacingOccurrences(of: "\(currencySymbol!)", with: "")) as! NSDecimalNumber
        
        mInvoice.addItem("My Order", quantity: 1, unitPrice: price, itemId: 123, detailId: nil)
        
        // The invoice Number is used for duplicate payment checking.  It should be unique for every
        // unique transaction attempt.  For payment resubmissions, simply use the same invoice number
        // to ensure that the invoice hasn't already been paid. For sample purposes, this app is
        // simply generating a random number to append to the string 'sdk2test'.
        mInvoice.number = "sdk2test\(arc4random_uniform(99999))"
        
        guard mInvoice.itemCount > 0, mInvoice.total!.intValue >= 1 else {
            let alertController = UIAlertController(title: "Whoops!", message: "Either there are no line items or the total amount is less than \(currencySymbol!)1", preferredStyle: UIAlertControllerStyle.alert)
            
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
        createInvoiceBtn.changeToButtonWasSelected(self.createInvoiceBtn)
        
        createTxnBtn.isEnabled = true
        
    }
    
    // This function does the createTransaction call to start the process with the current invoice.
    @IBAction func createTransaction(_ sender: CustomButton) {
        
        PayPalRetailSDK.transactionManager()?.createTransaction(invoice, callback: { (error, context) in
            self.tc = context
            
            self.createTxnBtn.changeToButtonWasSelected(self.createTxnBtn)
            self.createTxnBtn.isEnabled = false
            self.acceptTxnBtn.isEnabled = true
        })
    }
    
    // This function will activate the reader by calling the begin method of TransactionContext.  This will
    // activate the reader and have it show the payment methods available for payment.  The listeners are
    // set in this function as well to allow for the listening of the user either inserting, swiping, or tapping
    // their payment device.
    @IBAction func acceptTransaction(_ sender: CustomButton) {
        
        // This card presented listener is optional as the SDK will automatically continue when the card is
        // presented even if this listener is not implemented.
        tc!.setCardPresentedHandler { (cardInfo) -> Void in
            self.tc!.continue(with: cardInfo)
        }
        
        tc!.setCompletedHandler { (error, txnRecord) -> Void in
            
            if let err = error {
                print("Error Code: \(String(describing: err.code))")
                print("Error Message: \(String(describing: err.message))")
                print("Debug ID: \(String(describing: err.debugId))")
                
                return
            } else {
                if let txnRecord = txnRecord {
                    if let transactionNumber = txnRecord.transactionNumber {
                        self.transactionNumber = transactionNumber
                        print("Txn ID: \(transactionNumber)")
                    }
                    self.paymentMethod = txnRecord.paymentMethod
                }
                self.navigationController?.popToViewController(self, animated: false)
                
                if (self.options?.isAuthCapture)! {
                    self.goToAuthCompletedViewController()
                } else {
                    self.goToPaymentCompletedViewController()
                }
            }
        }
        
        if(self.offlineMode) {
            tc?.setOfflineTransactionAdditionHandler({ (error, offlineTxnRecord) in
                if let err = error {
                    print("Offline Save Error Code: \(String(describing: err.code))")
                    print("Offline Save Error Message: \(String(describing: err.message))")
                    print("Offline Save Debug ID: \(String(describing: err.debugId))")
                } else {
                    self.goToOfflinePaymentCompletedViewController()
                }
            })
        }
        tc!.beginPayment(options)
    }
    
    @IBAction func offlinePaymentMode(_ sender: CustomButton) {
        if (self.tc != nil) {
            let noOfflineAlert = UIAlertController(title: "Whoops!", message: "Cannot enable offline mode when a transaction context is already created.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                print("Error - trying to enable offline mode when transaction context has already been created.")
            }
            
            noOfflineAlert.addAction(okAction)
            self.present(noOfflineAlert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "offlineModeVC", sender: self)
        }
    }
    
    @IBAction func paymentOptions(_ sender: CustomButton) {
        if(self.offlineMode) {
            let noOptionAlert = UIAlertController(title: "Whoops!", message: "Transaction options are not available in offline mode.", preferredStyle: UIAlertControllerStyle.alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                print("Error - transaction options aren't available in offline mode.")
            }
            
            noOptionAlert.addAction(okAction)
            self.present(noOptionAlert, animated: true, completion: nil)
        } else {
            performSegue(withIdentifier: "transactionOptionsVC", sender: self)
        }
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
        
        if let offlineController = segue.destination as? OfflineModeViewController {
            offlineController.delegate = self
            offlineController.offlineMode = self.offlineMode
        }
        
        if let transactionOptionsController = segue.destination as? TransactionOptionsViewController {
            transactionOptionsController.delegate = self
            transactionOptionsController.formFactorArray = self.formFactorArray
            transactionOptionsController.transactionOptions = self.options
        }
    }
    
    func goToPaymentCompletedViewController() {
        performSegue(withIdentifier: AppStrings.segueNames.paymentCompletedController, sender: Any?.self)
    }
    
    func goToAuthCompletedViewController() {
        performSegue(withIdentifier: "goToAuthCompletedView", sender: Any?.self)
    }
    
    func goToOfflinePaymentCompletedViewController(){
        performSegue(withIdentifier: "offlinePaymentCompletedVC", sender: self)
    }
    
    private func setUpDefaultView(){
        setUpTextFieldToolBar()
        createInvCodeView.text = "mInvoice = PPRetailRetailInvoice.init(currencyCode: \"USD\")"
        createTxnCodeView.text = "PayPalRetailSDK.transactionManager().createTransaction(invoice, callback: { (error, context) in \n" +
            "  // Set the transactionContext or handle the error \n" +
            "  self.tc = context \n" +
        "}))"
        offlineModeBtn.changeButtonTitle(offline: self.offlineMode, forButton: offlineModeBtn)
        acceptTxnCodeView.text = "tc.beginPayment(options)"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    private func setUpTextFieldToolBar(){
        //init toolbar for keyboard
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.invAmount.inputAccessoryView = toolbar

        // Add target to receive text change
        invAmount.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }
    
    // Function to handle real-time changes in the invoice/payment amount text field.  The
    // create invoice button is disabled unless there is a value in the box.
    @objc func editingChanged(_ textField: UITextField) {
        
        if let amountString = textField.text?.currencyInputFormatting() {
            textField.text = amountString
        }
        
        guard let amt = invAmount.text, !amt.isEmpty else {
            createInvoiceBtn.isEnabled = false
            return
        }
        
        createInvoiceBtn.isEnabled = true
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }
}

extension PaymentViewController: OfflineModeViewControllerDelegate, TransactionOptionsViewControllerDelegate {
    
    func transactionOptions(controller: TransactionOptionsViewController, options: PPRetailTransactionBeginOptions) {
        self.options = options
    }
    
    func transactionOptionsFormFactors(controller: TransactionOptionsViewController, formFactors: [PPRetailFormFactor]!) {
        self.formFactorArray = formFactors
    }
    
    func offlineMode(controller: OfflineModeViewController, didChange isOffline: Bool) {
        self.offlineMode = isOffline
        offlineModeBtn.changeButtonTitle(offline: self.offlineMode, forButton: offlineModeBtn)
    }
    
    
}

extension PPRetailTransactionBeginOptions {
    
    class func defaultOptions() -> PPRetailTransactionBeginOptions? {
        // Setting up the options for the transaction
        guard let options = PPRetailTransactionBeginOptions() else {return nil}
        options.showPromptInCardReader = true
        options.showPromptInApp = true
        options.preferredFormFactors = []
        options.tippingOnReaderEnabled = false
        options.amountBasedTipping = false
        options.quickChipEnabled = false
        options.isAuthCapture = false
        options.tag = ""
        return options
    }
}
