//
//  PaymentCompletedViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 12/19/17.
//  Copyright © 2017 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class PaymentCompletedViewController: UIViewController {
    
    @IBOutlet weak var provideRefundBtn: UIButton!
    @IBOutlet weak var successMsg: UILabel!
    @IBOutlet weak var viewRefundCodeBtn: UIButton!
    @IBOutlet weak var refundCodeViewer: UITextView!
    
    var invoice: PPRetailInvoice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refundCodeViewer.isHidden = true
        successMsg.text = "Your payment of $\(invoice?.total ?? 0) was successful"
        successMsg.sizeToFit()
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // This function will process the refund.
    @IBAction func provideRefund(_ sender: Any) {
        
        guard let tc = PayPalRetailSDK.createTransaction(invoice) else {
            print("Something went wrong while creating the transactionContext for the refund")
            return
        }
        
        tc.setCardPresentedHandler { (cardInfo) -> Void in
            tc.continue(with: cardInfo)
        }
        
        tc.setCompletedHandler { (error, txnRecord) -> Void in
            
            if let err = error {
                print("Error Code: \(err.code)")
                print("Error Message: \(err.message)")
                print("Debug ID: \(err.debugId)")
                
                return
            }
            print("Refund ID: \(txnRecord!.transactionNumber!)")

            self.navigationController?.popToViewController(self, animated: false)
            self.noThanksBtn(nil)
        }
        
        tc.beginRefund(true, amount: tc.invoice?.total)
    }
    
    @IBAction func showRefundCode(_ sender: Any) {
        if (refundCodeViewer.isHidden) {
            viewRefundCodeBtn.setTitle("Hide Code", for: .normal)
            refundCodeViewer.isHidden = false
            refundCodeViewer.text = "tc.beginRefund(true, amount: tc.invoice?.total)"
        } else {
            viewRefundCodeBtn.setTitle("View Code", for: .normal)
            refundCodeViewer.isHidden = true
        }
    }
    
    // If the 'No Thanks' button is selected, we direct back to the PaymentViewController
    // so that more transactions can be run.
    @IBAction func noThanksBtn(_ sender: UIButton?) {
        
        performSegue(withIdentifier: "goToPaymentsView", sender: sender)
        
    }
    
}
