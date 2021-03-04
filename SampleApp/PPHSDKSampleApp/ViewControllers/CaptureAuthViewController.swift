//
//  CaptureAuthViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 1/9/18.
//  Copyright © 2018 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class CaptureAuthViewController: UIViewController {
    
    @IBOutlet weak var captureAmount: UITextField!
    @IBOutlet weak var captureAuthBtn: UIButton!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var enterAmountLbl: UILabel!
    
    var invoice: PPRetailRetailInvoice?
    var authTransactionNumber: String?
    var paymentMethod: PPRetailInvoicePaymentMethod?
    var captureTransactionNumber: String?
    var capturedAmount: NSDecimalNumber?
    var isTip: Bool?
    var gratuityAmt: NSDecimalNumber = 0
    var currencySymbol: String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        
        setUpTextFieldToolbar()
        captureAmount.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        
        if(isTip)! {
            enterAmountLbl.text = "Enter a tip amount"
            captureAuthBtn.setTitle("Capture Tip", for: .normal)
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        captureAmount.becomeFirstResponder()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let userDefaults = UserDefaults.init()
        currencySymbol = userDefaults.value(forKey: "CURRENCY_SYMBOL") as! String
        captureAmount.placeholder = "\(currencySymbol!) 0.00"
    }
    
    @IBAction func captureAuthorization(_ sender: UIButton) {
        var amountToCapture: NSDecimalNumber = 0
        
        guard captureAmount.text != "" else {
            let alertController = UIAlertController(title: "Whoops!", message: "You need to enter a capture amount", preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                print("Invalid Capture Amount")
            }
            
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
            
            return
        }
        
        activitySpinner.isHidden = false
        activitySpinner.startAnimating()
        captureAuthBtn.isEnabled = false
        
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        let inputtedAmount = formatter.number(from: captureAmount.text!.replacingOccurrences(of: "\(currencySymbol!)", with: "")) as! NSDecimalNumber
        
        if(isTip)! {
            amountToCapture = (invoice?.total?.adding(inputtedAmount))!
            gratuityAmt = inputtedAmount
        } else {
            amountToCapture = inputtedAmount
        }
        
        PayPalRetailSDK.transactionManager()?.captureAuthorization(authTransactionNumber, invoiceId: invoice?.payPalId, totalAmount: amountToCapture, gratuityAmount: gratuityAmt, currency: invoice?.currency) { (error, captureId) in
            
            if let err = error {
                print("Error Code: \(String(describing: err.code))")
                print("Error Message: \(String(describing: err.message))")
                print("Debug ID: \(String(describing: err.debugId))")
                
                self.activitySpinner.stopAnimating()
                return
            }
            print("Capture ID: \(String(describing: captureId))")
            
            self.captureTransactionNumber = captureId
            self.capturedAmount = amountToCapture
            self.activitySpinner.stopAnimating()
            self.goToPaymentCompletedViewController()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let pmtCompletedViewController = segue.destination as? PaymentCompletedViewController {
            pmtCompletedViewController.isCapture = true
            pmtCompletedViewController.capturedAmount = capturedAmount
            pmtCompletedViewController.paymentMethod = paymentMethod
            // For Auth-Capture, use the captureId returned by captureAuthorization as the transactionNumber for refunds
            pmtCompletedViewController.transactionNumber = captureTransactionNumber
            pmtCompletedViewController.isTip = isTip
            if(isTip)! {
                pmtCompletedViewController.gratuityAmt = gratuityAmt
            }
        }
    }
    
    func goToPaymentCompletedViewController() {
        performSegue(withIdentifier: "goToPmtCompletedView", sender: Any?.self)
    }
    
    // Function to handle real-time changes in the invoice/payment amount text field.  The
    // create invoice button is disabled unless there is a value in the box.
    @objc func editingChanged(_ textField: UITextField) {
        
        if let amountString = textField.text?.currencyInputFormatting() {
            textField.text = amountString
        }
        
    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }
    
    private func setUpTextFieldToolbar(){
        //init toolbar for keyboard
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 50))
        let customDoneButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: toolbar.bounds.size.width, height: toolbar.bounds.size.height))
        customDoneButton.setTitle("Done", for: .normal)
        customDoneButton.setTitleColor(.white, for: .normal)
        customDoneButton.backgroundColor = UIColor().hexStringToUIColor(hex: "0065B1")
        customDoneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        let doneBtn = UIBarButtonItem(customView: customDoneButton)
        toolbar.setItems([doneBtn], animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.captureAmount.inputAccessoryView = toolbar
    }
    
    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
}
