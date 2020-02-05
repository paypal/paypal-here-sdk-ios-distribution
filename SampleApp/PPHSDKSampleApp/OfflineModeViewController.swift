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
    @IBOutlet weak var getOfflineStatusBtn: CustomButton!
    @IBOutlet weak var getOfflineStatusCodeTxtView: UITextView!
    @IBOutlet weak var replayOfflineTransactionBtn: CustomButton!
    @IBOutlet weak var replayOfflineTransactionCodeTxtView: UITextView!
    @IBOutlet weak var replayTransactionIndicatorView: UIActivityIndicatorView!
    @IBOutlet weak var stopReplayBtn: CustomButton!
    @IBOutlet weak var stopReplayCodeTxtView: UITextView!
    @IBOutlet weak var replayTransactionResultsTextView: UITextView!
    @IBOutlet weak var offlineModeLabel: UILabel!
    
    // Local Flag for offline Mode
    var offlineMode: Bool!
    var offlineSDK: Bool = false
    
    weak var delegate: OfflineModeViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpDefaultView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.offlineMode(controller: self, didChange: self.offlineMode)
    }
    
    /// If the offlineModeSwitch is toggled. Call the toggleOfflineMode() function.
    /// - Parameter sender: UISwitch for the offlineMode.
    @IBAction func offlineModeSwitchPressed(_ sender: UISwitch) {
        toggleOfflineMode()
    }
    
    /// If offlineMode is set to true then we will start taking offline payments and if it is set to false
    /// then we stop taking offline payments. To Start/Stop taking offline payments, we ned to make a call to
    /// the SDK. If we start taking online payments then we MUST call the stopOfflinePayment() in order to start
    /// taking live payments again.
    /// FOR UI ONLY - Change the UI based on offlineMode flag.
    private func toggleOfflineMode(){
        if !offlineMode {
            // If the merchant is whitelisted to take offline Payments.
            if (PayPalRetailSDK.transactionManager()?.getOfflinePaymentEligibility())! {
                // This call with initalize offlinePayment. Any kind of failure will be returned to this callback.
                // Along with the status of the transaction that were done during offline Mode.
                PayPalRetailSDK.transactionManager()?.startOfflinePayment({ (error, info) in
                    if error != nil {
                        print(error?.developerMessage ?? "There was a problem initializing offlinePayment.")
                    } else {
                        // Check to see if OfflinePayment was enabled
                        if (PayPalRetailSDK.transactionManager()?.getOfflinePaymentEnabled())! {
                            self.updateOfflineModeUI()
                        }
                        self.offlineTransactionStatusList(statusList: info?.statusList)
                    }
                })
            } else {
                print("Merchant is not eligible to take Offline Payments")
                self.alertMerchantNotEligableForOfflinePayments()

            }
        } else {
            // Turn off offlineMode
            PayPalRetailSDK.transactionManager()?.stopOfflinePayment({ (error, info) in
                if error != nil {
                    print("Error: \(error.debugDescription)")
                } else {
                    self.offlineTransactionStatusList(statusList: info?.statusList)
                }
            })
            self.updateOfflineModeUI()
        }
    }
    
    /// The function will get the offline Status. It is a callback. It will give you an array of status which will
    /// tell you about the status of the payment.
    /// - Parameter sender: CustomButton assoicated with the Get Offline Status button.
    @IBAction func getOfflineStatus(_ sender: CustomButton) {
        PayPalRetailSDK.transactionManager().getOfflinePaymentStatus { (error, info) in
            if error  != nil {
                print("Error: \(error.debugDescription)")
            } else {
                self.offlineTransactionStatusList(statusList: info?.statusList)
            }
        }
    }
    
    /// If payments are taken in offline mode then those payments are saved on the device. This function, if the
    /// device is online, will go through those payments saved on the device and process those payments.
    /// The call back will give you the result whether those payments are completed, failed or were declined.
    /// - Parameter sender: CustomButton associated with "Replay Offline Transaction" button
    @IBAction func replayOfflineTransaction(_ sender: CustomButton) {
        
        if offlineSDK {
            showReplayTransactionAlert(offlineInit: true)
        } else {
            if offlineMode {
                showReplayTransactionAlert(offlineInit: false)
            }
            
            self.replayTransactionAnimation(true)
            PayPalRetailSDK.transactionManager().startReplayOfflineTxns { [unowned self] (error, info) in
                self.updateOfflineModeUI()
                self.replayTransactionAnimation(false)
                if error != nil {
                    print("Error is: ", error.debugDescription)
                } else {
                    self.offlineTransactionStatusList(statusList: info?.statusList)
                }
            }
        }
    }
    
    /// If we are replaying transactions and we want to stop replayingTransactions then we can call this function.
    /// For example: If you went offline when replaying transactions.
    /// - Parameter sender: CustomButton associated with "Stop Replay" Button
    @IBAction func stopReplay(_ sender: CustomButton) {
        replayTransactionIndicatorView.stopAnimating()
        replayOfflineTransactionBtn.isHidden = false
        PayPalRetailSDK.transactionManager()?.stopReplayOfflineTxns({ (error, info) in
            if error != nil {
                print("Stopped replaying offline transactions")
            } else {
                self.offlineTransactionStatusList(statusList: info?.statusList)
            }
        })
    }
    
    private func offlineTransactionStatusList(statusList: [Any]?){
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
        self.replayTransactionResultsTextView.text = "Uncompleted: \(uncompleted) \nCompleted: \(completed) \nFailed: \(failed) \nDeclined: \(declined)"
        self.stopReplayBtn.isEnabled = false
    }
    
    private func setUpDefaultView(){
        /// Set the offlineMode switch on/off according to the value passed from PaymentViewController. Originally false.
        offlineModeSwitch.isOn = offlineMode
        // Stop Replay Button is only needed when we are replaying transactions. Otherwise it is disabled.
        stopReplayBtn.isEnabled = false
        getOfflineStatusCodeTxtView.text = "PayPalRetailSDK.transactionManager().getOfflinePaymentStatus({ (error, statusList) in // Code })"
        replayOfflineTransactionCodeTxtView.text = "PayPalRetailSDK.transactionManager().startReplayOfflineTxns({ (error, statusList) in // Code })"
        stopReplayCodeTxtView.text = "PayPalRetailSDK.transactionManager().stopReplayOfflineTxns()"
        self.replayTransactionResultsTextView.text = "Uncompleted: 0 \nCompleted: 0 \nFailed: 0 \nDeclined: 0"
        updateOfflineModeUI()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        offlineSDKInit()
    }
    
    @objc private func offlineSDKInit(){
        let tokenDefault = UserDefaults.init()
        guard (tokenDefault.value(forKey: "offlineSDKInit") != nil) else { return }
        self.offlineSDK = tokenDefault.bool(forKey: "offlineSDKInit")
        self.offlineModeSwitch.isEnabled = false
    }
    
    private func updateOfflineModeUI(){
        if (PayPalRetailSDK.transactionManager()?.getOfflinePaymentEnabled())! {
            offlineMode = true
            offlineModeLabel.text = "ENABLED"
            offlineModeLabel.textColor = .green
            offlineModeSwitch.isOn = true
        } else {
            offlineMode = false
            offlineModeLabel.text = ""
            offlineModeLabel.textColor = .red
            offlineModeSwitch.isOn = false
        }
    }
    
    private func replayTransactionAnimation(_ start: Bool){
        if start {
            replayTransactionIndicatorView.startAnimating()
            replayOfflineTransactionBtn.isHidden = true
            stopReplayBtn.isEnabled = true
        } else {
            replayTransactionIndicatorView.stopAnimating()
            replayOfflineTransactionBtn.isHidden = false
            stopReplayBtn.isEnabled = false
        }
    }
    
    private func showReplayTransactionAlert(offlineInit: Bool){
        var title: String = "Replaying while in Offline Mode"
        var message: String = "Replaying transaction in offlineMode will bring the SDK back into Online Mode"
        
        if offlineInit {
            title = "Cannot Replay in Offline Init"
            message = "Replay is not allowed while the SDK is initialized in offline Mode."
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func alertMerchantNotEligableForOfflinePayments() {
        let alertController = UIAlertController(title: "Whoops!", message: "Merchant is not eligible to take Offline Payments", preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            self.offlineModeSwitch.setOn(false, animated: true)
        }
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
}
