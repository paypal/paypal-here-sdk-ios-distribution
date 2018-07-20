//
//  AuthCompletedViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 1/8/18.
//  Copyright © 2018 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class AuthCompletedViewController: UIViewController {

    @IBOutlet weak var successMsg: UILabel!
    @IBOutlet weak var voidAuthBtn: CustomButton!
    @IBOutlet weak var voidCodeViewer: UITextView!
    @IBOutlet weak var captureAuthBtn: CustomButton!
    @IBOutlet weak var captureAuthCodeViewer: UITextView!
    
    var invoice: PPRetailInvoice?
    var authTransactionNumber: String?
    var paymentMethod: PPRetailInvoicePaymentMethod?
    var isTip: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDefaultView()
        successMsg.text = "Your authorization of $\(invoice?.total ?? 0) was successful"
        successMsg.sizeToFit()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func voidAuthorization(_ sender: UIButton) {
        
        PayPalRetailSDK.transactionManager().voidAuthorization(authTransactionNumber) { (error) in
            if let err = error {
                print("Error Code: \(String(describing: err.code))")
                print("Error Message: \(String(describing: err.message))")
                print("Debug ID: \(String(describing: err.debugId))")
                return
            }
            
            print("Void Payment was successful.")
            
            let alertController = UIAlertController(title: "Voided Successfully", message: "The payment was voided successfully. Start Over.", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "Start Over", style: .default, handler: { (action) in
                 self.performSegue(withIdentifier: "goToPaymentsView", sender: sender)
            }))
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goToCaptureAuthView") {
            if let captureAuthViewController = segue.destination as? CaptureAuthViewController {
                captureAuthViewController.authTransactionNumber = authTransactionNumber
                captureAuthViewController.invoice = invoice
                captureAuthViewController.paymentMethod = paymentMethod
                captureAuthViewController.isTip = isTip
            }
        }
    }
    
    @IBAction func captureAuthorization(_ sender: UIButton) {
        let alert = UIAlertController(title: "Adding a tip?", message: "Are you trying to do a regular capture or add a tip to a previous transaction?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Capture", style: .default, handler: {action in
            self.isTip = false
            self.performSegue(withIdentifier: "goToCaptureAuthView", sender: sender)
        }))
        alert.addAction(UIAlertAction(title: "Add Tip", style: .default, handler: {action in
            self.isTip = true
            self.performSegue(withIdentifier: "goToCaptureAuthView", sender: sender)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = captureAuthBtn
            popoverController.sourceRect = captureAuthBtn.bounds
        }
        
        self.present(alert, animated: true)
    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }
    
    private func setUpDefaultView(){
        
        voidCodeViewer.text = "PayPalRetailSDK.transactionManager().voidAuthorization(authTransactionNumber) { (error) in\n" +
            "   <code to handle success/failure>\n" +
        "}"
        captureAuthCodeViewer.text = "PayPalRetailSDK.captureAuthorizedTransaction(authTransactionNumber, invoiceId: invoice.payPalId, totalAmount: amountToCapture, gratuityAmount: 0, currency: invoice.currency) { (error, captureId) in\n" +
            "  <code to handle success/failure>\n" +
        "}"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

}
