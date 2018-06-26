//
//  OfflineModeViewController.swift
//  PPHSDKSampleApp
//
//  Created by Deol, Sukhpreet(AWF) on 6/21/18.
//  Copyright © 2018 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

protocol OfflineModeViewControllerDelegate: NSObjectProtocol {
    func offlineMode(controller: OfflineModeViewController, didChange isOffline: Bool)
}

class OfflineModeViewController: UIViewController {
    
    @IBOutlet weak var offlineModeSwitch: UISwitch!
    @IBOutlet weak var getOfflineStatusBtn: UIButton!
    @IBOutlet weak var getOfflineStatusViewCodeBtn: UIButton!
    @IBOutlet weak var getOfflineStatusCodeTxtView: UITextView!
    @IBOutlet weak var replayOfflineTransactionBtn: UIButton!
    @IBOutlet weak var replayOfflineTransactionViewCodeBtn: UIButton!
    @IBOutlet weak var replayOfflineTransactionCodeTxtView: UITextView!
    @IBOutlet weak var stopReplayBtn: UIButton!
    @IBOutlet weak var stopReplayViewCodeBtn: UIButton!
    @IBOutlet weak var stopReplayCodeTxtView: UITextView!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBOutlet weak var replayTransactionIndicatorView: UIActivityIndicatorView!
    
    /// If offlineMode is set to true then we will start taking offline payments and if it is set to false
    /// then we stop taking offline payments. To Start/Stop taking offline payments, we ned to make a call to
    /// the SDK. If we start taking online payments then we MUST call the stopOfflinePayment() in order to start
    /// taking live payments again.
    var offlineMode: Bool! {
        didSet{
            if offlineMode {
                PayPalRetailSDK.transactionManager().startOfflinePayment()
                NotificationCenter.default.post(name: .offlineModeIsChanged, object: nil)
                
            } else {
                PayPalRetailSDK.transactionManager().stopOfflinePayment()
                NotificationCenter.default.post(name: .offlineModeIsChanged, object: nil)
            }
        }
    }
    
    weak var delegate: OfflineModeViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /// Set the offlineMode switch on/off according to the value passed from PaymentViewController. Originally false.
        offlineModeSwitch.isOn = offlineMode
        
        // Stop Replay Button is only needed when we are replaying transactions. Otherwise it is disabled.
        stopReplayBtn.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector:#selector(enableReplayTransactionButton), name: .offlineModeIsChanged , object: nil)
    }
    
    /// If the offlineModeSwitch is toggled. Set the value for the offlineMode Flag which will make the appropriate call
    /// to the SDK.
    /// - Parameter sender: UISwitch for the offlineMode.
    @IBAction func offlineModeSwitchPressed(_ sender: UISwitch) {
        offlineMode = offlineModeSwitch.isOn
    }
    
    /// The function will get the offline Status. It is a callback. It will give you an array of status which will
    /// tell you about the status of the payment.
    /// - Parameter sender: UIButton assoicated with the Get Offline Status button.
    @IBAction func getOfflineStatus(_ sender: UIButton) {
        PayPalRetailSDK.transactionManager().getOfflinePaymentStatus { (error, statusList) in
            if error  != nil {
                print("Error: ", error?.debugDescription ?? "")
            } else {
                guard let statusArray: [PPRetailOfflinePaymentStatus] = statusList as? [PPRetailOfflinePaymentStatus] else {return}
                var uncompleted: Int = 0
                var completed: Int = 0
                var failed: Int = 0
                var declined: Int = 0
                
                for status in statusArray {
                    if status.errNo == 0 {
                        if status.retry > 0 {
                            completed += 1
                        } else {
                            uncompleted += 1
                        }
                    } else if status.isDeclined {
                        declined += 1
                    } else {
                        failed += 1
                    }
                }
                self.resultsLabel.text = "Results: Uncompleted: \(uncompleted) | completed: \(completed) | Failed: \(failed) | Declined: \(declined)"
            }
        }
    }
    
    /// If payments are taken in offline mode then those payments are saved on the device. This function, if the
    /// device is online, will go through those payments saved on the device and process those payments.
    /// The call back will give you the result whether those payments are completed, failed or were declined.
    /// - Parameter sender: UIButton associated with "Replay Offline Transaction" button
    @IBAction func replayOfflineTransaction(_ sender: UIButton) {
        replayTransactionIndicatorView.startAnimating()
        stopReplayBtn.isEnabled = true
        PayPalRetailSDK.transactionManager().startReplayOfflineTxns { [unowned self] (error, statusList) in
            self.replayTransactionIndicatorView.stopAnimating()
            
            if error != nil {
                print("Error is: ", error.debugDescription)
            } else {
                guard let statusArray: [PPRetailOfflinePaymentStatus] = statusList as? [PPRetailOfflinePaymentStatus] else {return}
                var completed: Int = 0
                var failed: Int = 0
                var declined: Int = 0
                
                for status in statusArray {
                    if status.errNo == 0 {
                        completed += 1
                    } else if status.isDeclined {
                        declined += 1
                    } else {
                        failed += 1
                    }
                }
                self.resultsLabel.text = "Results: Completed: \(completed) | Failed: \(failed) | Declined: \(declined)"
                self.stopReplayBtn.isEnabled = false
            }
        }
    }
    
    
    /// If we are replaying transactions and we want to stop replayingTransactions then we can call this function.
    /// For example: If you went offline when replaying transactions.
    /// - Parameter sender: UIButton associated with "Stop Replay" Button
    @IBAction func stopReplay(_ sender: UIButton) {
        replayTransactionIndicatorView.stopAnimating()
        PayPalRetailSDK.transactionManager().stopReplayOfflineTxns()
    }
    
    /// This function will pass the offlineMode value to the PaymentViewController and dimiss this controller.
    /// - Parameter sender: "Run Transaction" button
    @IBAction func runTransaction(_ sender: UIButton) {
        self.delegate?.offlineMode(controller: self, didChange: self.offlineMode)
        dismiss(animated: true, completion: nil)
    }
    
    /// THIS FUNCTION IS ONLY FOR UI. This funciton will show/hide code snippets for the appropriate function calls.
    /// Here, we are basically checking thier tags and changing the UI appropriatly.
    /// - Parameter sender: View/Hide Code Buttons
    @IBAction func viewCodeBtnPressed(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            if getOfflineStatusCodeTxtView.isHidden {
                getOfflineStatusViewCodeBtn.setTitle("Hide Code", for: .normal)
                getOfflineStatusCodeTxtView.isHidden = false
                getOfflineStatusCodeTxtView.text = "PayPalRetailSDK.transactionManager().getOfflinePaymentStatus({ (error, statusList) in // Code })"
            } else {
                getOfflineStatusViewCodeBtn.setTitle("View Code", for: .normal)
                getOfflineStatusCodeTxtView.isHidden = true
            }
        case 1:
            if replayOfflineTransactionCodeTxtView.isHidden {
                replayOfflineTransactionViewCodeBtn.setTitle("Hide Code", for: .normal)
                replayOfflineTransactionCodeTxtView.isHidden = false
                replayOfflineTransactionCodeTxtView.text = "PayPalRetailSDK.transactionManager().startReplayOfflineTxns({ (error, statusList) in // Code })"
            } else {
                replayOfflineTransactionViewCodeBtn.setTitle("View Code", for: .normal)
                replayOfflineTransactionCodeTxtView.isHidden = true
            }
        case 2:
            if stopReplayCodeTxtView.isHidden {
                stopReplayViewCodeBtn.setTitle("Hide Code", for: .normal)
                stopReplayCodeTxtView.isHidden = false
                stopReplayCodeTxtView.text = "PayPalRetailSDK.transactionManager().stopReplayOfflineTxns()"
            } else {
                stopReplayViewCodeBtn.setTitle("View Code", for: .normal)
                stopReplayCodeTxtView.isHidden = true
            }
        default:
            break
        }
    }
    
    /// THIS FUNCTION IS ONLY FOR UI. This function will enable/disable "Replay Transaction" Button
    /// depending on if the offlineMode is on or off.
    /// - Parameter isEnabled: A Bool to enable/disable the "Replay Transaction Button"
    @objc private func enableReplayTransactionButton(){
        if offlineMode {
            replayOfflineTransactionBtn.isEnabled = false
        } else {
            replayOfflineTransactionBtn.isEnabled = true
        }
    }
}

extension Notification.Name {
    static let offlineModeIsChanged = Notification.Name("offlineModeIsChanged")
}
