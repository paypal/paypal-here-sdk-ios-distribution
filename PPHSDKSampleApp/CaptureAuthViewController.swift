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
    var authId: String?
    var paymentMethod: PPRetailInvoicePaymentMethod?
    var captureId: String?
    
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
        
        PayPalRetailSDK.transactionManager()?.captureAuthorization(authId, invoiceId: invoice?.payPalId, totalAmount: amountToCapture, gratuityAmount: 0, currency: invoice?.currency) { (error, captureId) in

            self.captureId = captureId
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.message)")
                print("Debug ID: \(err.debugId)")

                self.activitySpinner.stopAnimating()
                return
            }
            print("Capture ID: \(captureId)")
            self.activitySpinner.stopAnimating()
            self.goToPaymentCompletedViewController()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goToPmtCompletedView") {
            if let pmtCompletedViewController = segue.destination as? PaymentCompletedViewController {
                pmtCompletedViewController.isCapture = true
                pmtCompletedViewController.invoice = invoice
                pmtCompletedViewController.paymentMethod = paymentMethod
                pmtCompletedViewController.captureId = captureId                
            }
        }
    }
    
    func goToPaymentCompletedViewController() {
        performSegue(withIdentifier: "goToPmtCompletedView", sender: Any?.self)
    }
    
    // Function to handle real-time changes in the invoice/payment amount text field.  The
    // create invoice button is disabled unless there is a value in the box.
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
