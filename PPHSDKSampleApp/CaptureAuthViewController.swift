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
    
    var invoice: PPRetailInvoice?
    var authId: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        captureAmount.layer.borderColor = (UIColor(red: 0/255, green: 159/255, blue: 228/255, alpha: 1)).cgColor
        captureAmount.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        
        captureAuthBtn.isHidden = false
    }

    @IBAction func captureAuthorization(_ sender: UIButton) {
        
        captureAuthBtn.isEnabled = false
        let formatter = NumberFormatter()
        formatter.generatesDecimalNumbers = true
        let amountToCapture = formatter.number(from: captureAmount.text!.replacingOccurrences(of: "$", with: "")) as! NSDecimalNumber
        
        PayPalRetailSDK.transactionManager()?.captureAuthorization(authId, invoiceId: invoice?.payPalId, totalAmount: amountToCapture, gratuityAmount: 0, currency: invoice?.currency) { (error, captureId) in
            
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.message)")
                print("Debug ID: \(err.debugId)")
                
                return
            }
            print("Capture ID: \(captureId)")
            
            self.goToPaymentCompletedViewController()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goToPmtCompletedView") {
            if let pmtCompletedViewController = segue.destination as? PaymentCompletedViewController {
                pmtCompletedViewController.invoice = invoice
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
        
        guard let amt = captureAmount.text, !amt.isEmpty else {
            captureAuthBtn.isEnabled = false
            return
        }
        
        captureAuthBtn.isEnabled = true
    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }
}
