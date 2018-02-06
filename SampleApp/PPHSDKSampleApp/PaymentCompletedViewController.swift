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
    var isCapture: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refundCodeViewer.isHidden = true
        if(isCapture) {
            successMsg.text = "Your capture of $\(invoice?.total ?? 0) was successful"
        } else {
            successMsg.text = "Your payment of $\(invoice?.total ?? 0) was successful"
        }
        successMsg.sizeToFit()
    }
    
    override func viewDidAppear(_ animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // This function will process the refund. You first have to create a TransactionContext, then set the appropriate
    // listeners, and then call beginRefund. Calling beginRefund with true and the amount will first prompt
    // if there's a card available or not. Based on that selection, the refund will process for the amount
    // supplied and the completion handler will be called afterwards.
    @IBAction func provideRefund(_ sender: Any) {

        PayPalRetailSDK.transactionManager()?.createTransaction(invoice, callback: { (error, tc) in
            
            // This card presented listener is optional as the SDK will automatically continue if a card is
            // presented for a refund.
            tc?.setCardPresentedHandler { (cardInfo) -> Void in
                tc?.continue(with: cardInfo)
            }
            
            tc?.setCompletedHandler { (error, txnRecord) -> Void in
                
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
            
            tc?.beginRefund(true, amount: tc?.invoice?.total)
        })
    }
    
    @IBAction func showRefundCode(_ sender: Any) {
        if (refundCodeViewer.isHidden) {
            viewRefundCodeBtn.setTitle("Hide Code", for: .normal)
            refundCodeViewer.isHidden = false
            refundCodeViewer.text = "tc.beginRefund(true, amount: tc.invoice.total)"
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
