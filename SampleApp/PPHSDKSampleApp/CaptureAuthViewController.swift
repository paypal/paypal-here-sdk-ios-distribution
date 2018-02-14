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
    
    var invoice: PPRetailInvoice?
    var authTransactionNumber: String?
    var paymentMethod: PPRetailInvoicePaymentMethod?
    var captureTransactionNumber: String?
    var capturedAmount: NSDecimalNumber?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //init toolbar for keyboard
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(CaptureAuthViewController.doneButtonAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        //setting toolbar as inputAccessoryView
        self.captureAmount.inputAccessoryView = toolbar

        captureAmount.layer.borderColor = (UIColor(red: 0/255, green: 159/255, blue: 228/255, alpha: 1)).cgColor
        captureAmount.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        captureAmount.becomeFirstResponder()
    }

    @IBAction func captureAuthorization(_ sender: UIButton) {
        
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
        let amountToCapture = formatter.number(from: captureAmount.text!.replacingOccurrences(of: "$", with: "")) as! NSDecimalNumber
        
        PayPalRetailSDK.transactionManager()?.captureAuthorization(authTransactionNumber, invoiceId: invoice?.payPalId, totalAmount: amountToCapture, gratuityAmount: 0, currency: invoice?.currency) { (error, captureId) in

            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.message)")
                print("Debug ID: \(err.debugId)")

                self.activitySpinner.stopAnimating()
                return
            }
            print("Capture ID: \(captureId)")
            
            self.captureTransactionNumber = captureId
            self.capturedAmount = amountToCapture
            self.activitySpinner.stopAnimating()
            self.goToPaymentCompletedViewController()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goToPmtCompletedView") {
            if let pmtCompletedViewController = segue.destination as? PaymentCompletedViewController {
                pmtCompletedViewController.isCapture = true
                pmtCompletedViewController.capturedAmount = capturedAmount
                pmtCompletedViewController.paymentMethod = paymentMethod
                // For Auth-Capture, use the captureId returned by captureAuthorization as the transactionNumber for refunds
                pmtCompletedViewController.transactionNumber = captureTransactionNumber
            }
        }
    }
    
    func goToPaymentCompletedViewController() {
        performSegue(withIdentifier: "goToPmtCompletedView", sender: Any?.self)
    }
    
    // Function to handle real-time changes in the amount text field.
    func editingChanged(_ textField: UITextField) {
        
        if let amountString = textField.text?.currencyInputFormatting() {
            textField.text = amountString
        }

    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }
    
    func doneButtonAction() {
        self.view.endEditing(true)
    }
}
