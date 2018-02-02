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
    var authId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        successMsg.text = "Your authorization of $\(invoice?.total ?? 0) was successful"
        successMsg.sizeToFit()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func voidAuthorization(_ sender: UIButton) {
        activitySpinner.startAnimating()
        
//        PayPalRetailSDK.voidAuthorization(authId) { (error) in
//            if let err = error {
//                print("Error Code: \(err.code)")
//                print("Error Message: \(err.message)")
//                print("Debug ID: \(err.debugId)")
//                self.activitySpinner.stopAnimating()
//                return
//            }
//            
//            self.activitySpinner.stopAnimating()
//            self.voidAuthBtn.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .normal)
//            self.voidSuccessLbl.isHidden = false
//            
//            self.captureAuthBtn.isEnabled = false
//            self.captureAuthBtn.setImage(#imageLiteral(resourceName: "small-grayarrow"), for: .disabled)
//            
//            self.startOverBtn.isHidden = false
//        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "goToCaptureAuthView") {
            if let captureAuthViewController = segue.destination as? CaptureAuthViewController {
                captureAuthViewController.authId = authId
                captureAuthViewController.invoice = invoice
            }
        }
    }
    
    @IBAction func captureAuthorization(_ sender: UIButton) {
        performSegue(withIdentifier: "goToCaptureAuthView", sender: sender)
    }
    
    @IBAction func showInfo(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            if (voidCodeViewer.isHidden) {
                voidAuthBtn.setTitle("Hide Code", for: .normal)
                voidCodeViewer.isHidden = false
                voidCodeViewer.text = "PayPalRetailSDK.voidAuthorization(authId) { (error) in\n" +
                                      "   <code to handle success/failure>\n" +
                                      "}"
            } else {
                voidAuthBtn.setTitle("View Code", for: .normal)
                voidCodeViewer.isHidden = true
            }
        case 1:
            if (captureAuthCodeViewer.isHidden) {
                captureAuthBtn.setTitle("Hide Code", for: .normal)
                captureAuthCodeViewer.isHidden = false
                captureAuthCodeViewer.text = "PayPalRetailSDK.captureAuthorizedTransaction(authId, invoiceId: invoice.payPalId, totalAmount: amountToCapture, gratuityAmount: 0, currency: invoice.currency) { (error, captureId) in\n" +
                                             "  <code to handle success/failure>\n" +
                                             "}"
            } else {
                captureAuthBtn.setTitle("View Code", for: .normal)
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
