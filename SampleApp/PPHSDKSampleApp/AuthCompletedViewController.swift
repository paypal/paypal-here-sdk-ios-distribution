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
    @IBOutlet weak var voidAuthBtn: UIButton!
    @IBOutlet weak var voidCodeViewBtn: UIButton!
    @IBOutlet weak var voidCodeViewer: UITextView!
    @IBOutlet weak var captureAuthBtn: UIButton!
    @IBOutlet weak var captureAuthCodeViewBtn: UIButton!
    @IBOutlet weak var captureAuthCodeViewer: UITextView!
    @IBOutlet weak var startOverBtn: UIButton!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var voidSuccessLbl: UILabel!
    
    var invoice: PPRetailInvoice?
    var authTransactionNumber: String?
    var paymentMethod: PPRetailInvoicePaymentMethod?
    var isTip: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        successMsg.text = "Your authorization of $\(invoice?.total ?? 0) was successful"
        successMsg.sizeToFit()
        activitySpinner.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func voidAuthorization(_ sender: UIButton) {
        activitySpinner.isHidden = false
        activitySpinner.startAnimating()
        
        PayPalRetailSDK.transactionManager().voidAuthorization(authTransactionNumber) { (error) in
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.message)")
                print("Debug ID: \(err.debugId)")
                self.activitySpinner.stopAnimating()
                return
            }

            self.activitySpinner.stopAnimating()
            self.activitySpinner.isHidden = true
            self.voidAuthBtn.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .normal)
            self.voidSuccessLbl.isHidden = false

            self.captureAuthBtn.isEnabled = false
            self.captureAuthBtn.setImage(#imageLiteral(resourceName: "small-grayarrow"), for: .disabled)

            self.startOverBtn.isHidden = false
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
        
        self.present(alert, animated: true)
    }
    
    @IBAction func showInfo(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            if (voidCodeViewer.isHidden) {
                voidCodeViewBtn.setTitle("Hide Code", for: .normal)
                voidCodeViewer.isHidden = false
                voidCodeViewer.text = "PayPalRetailSDK.transactionManager().voidAuthorization(authTransactionNumber) { (error) in\n" +
                                      "   <code to handle success/failure>\n" +
                                      "}"
            } else {
                voidCodeViewBtn.setTitle("View Code", for: .normal)
                voidCodeViewer.isHidden = true
            }
        case 1:
            if (captureAuthCodeViewer.isHidden) {
                captureAuthCodeViewBtn.setTitle("Hide Code", for: .normal)
                captureAuthCodeViewer.isHidden = false
                captureAuthCodeViewer.text = "PayPalRetailSDK.captureAuthorizedTransaction(authTransactionNumber, invoiceId: invoice.payPalId, totalAmount: amountToCapture, gratuityAmount: 0, currency: invoice.currency) { (error, captureId) in\n" +
                                             "  <code to handle success/failure>\n" +
                                             "}"
            } else {
                captureAuthCodeViewBtn.setTitle("View Code", for: .normal)
                captureAuthCodeViewer.isHidden = true
            }
        default:
            print("No Button Tag Found")
        }
    }
    
    @IBAction func startOver(_ sender: UIButton) {
        performSegue(withIdentifier: "goToPaymentsView", sender: sender)
    }
    
    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }

}
