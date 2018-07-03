//
//  DeviceDiscoveryViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 12/8/17.
//  Copyright © 2017 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class DeviceDiscoveryViewController: UIViewController {
    
    @IBOutlet weak var goToPmtPageBtn: UIButton!
    @IBOutlet weak var findAndConnect: UIButton!
    @IBOutlet weak var findAndConnectCodeBtn: UIButton!
    @IBOutlet weak var findAndConnectCodeView: UITextView!
    @IBOutlet weak var connectLastKnown: UIButton!
    @IBOutlet weak var connectLastKnownCodeBtn: UIButton!
    @IBOutlet weak var connectLastKnownCodeView: UITextView!
    @IBOutlet weak var activeReaderLbl: UILabel!
    @IBOutlet weak var autoConnectReader: UIButton!
    @IBOutlet weak var autoConnectReaderCodeBtn: UIButton!
    @IBOutlet weak var autoConnectReaderCodeView: UITextView!
    @IBOutlet weak var autoConnectActivityIndicator: UIActivityIndicatorView!
    
    let deviceManager = PayPalRetailSDK.deviceManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting up initial aesthetics
        findAndConnectCodeView.isHidden = true
        connectLastKnownCodeView.isHidden = true
        autoConnectReaderCodeView.isHidden = true
        goToPmtPageBtn.isHidden = false
        activeReaderLbl.text = ""
        
        // Watch for audio readers.
        // This will show a microphone connection permission prompt on the initial call (only once per app install)
        // Time this call such that it does not interfere with any other alerts
        // Requires a merchant, so start watching after a successful initializeMerchant
        // The audio reader may not be available to some merchants based on their location or other criteria
        // This is required if the app would like to use audio readers
        PayPalRetailSDK.startWatchingAudio()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Function to search for connected devices and show the UI to select which
    // device to use. As part of this function, we also need to include the process
    // of reader updates for our BT readers.
    @IBAction func findAndConnectReader(_ sender: Any) {
        deviceManager?.searchAndConnect({ (error, paymentDevice) -> Void in
            if let err = error {
                print("Search Device Error: \(err.debugId)")
                print("Search Device Error: \(err.code)")
                print("Search Device Error: \(err.message)")
                
                return
            }
            
            if(paymentDevice?.isConnected())! {
                self.activeReaderLbl.text = "Connected: \((paymentDevice?.id)!)"
                self.checkForReaderUpdate(reader:paymentDevice)
            }
        })
        
    }
    
    // Function to connect to the last known reader device used and check for any
    // reader updates.
    @IBAction func connectToLastReader(_ sender: Any) {
        deviceManager?.connect(toLastActiveReader: { (error, paymentDevice) -> Void in
            if let err = error {
                print("Connect Last Device Error: \(err.debugId)")
                print("Connect Last Device Error: \(err.code)")
                print("Connect Last Device Error: \(err.message)")
                self.activeReaderLbl.text = "Error: \(err.message ?? "Unknown")"
                return
            }
            if(paymentDevice?.isConnected())! {
                self.activeReaderLbl.text = "Connected: \((paymentDevice?.id)!)"
                self.checkForReaderUpdate(reader:paymentDevice)
            }
        })
    }
    
    /// Auto Connect to the last known reader. It will check for that reader in the
    /// background and connect to it automatically if it is available.
    /// - Parameter sender: UI Button on the screen "Auto Connect"
    @IBAction func autoConnectReader(_ sender: UIButton) {
        autoConnectActivityIndicator.startAnimating()
        guard let lastActiveReader = deviceManager?.getLastActiveBluetoothReader() else {
            autoConnectActivityIndicator.stopAnimating()
            activeReaderLbl.text = "No last known reader. Please Connect first."
            return
        }
        deviceManager?.scanAndAutoConnect(toBluetoothReader: lastActiveReader, callback: { (error, paymentDevice) in
            self.autoConnectActivityIndicator.stopAnimating()
            if error != nil {
                print("Error in connecting with bluetooth reader via Auto Connect: " + (error?.developerMessage)!)
                self.activeReaderLbl.text = "Error: \(error?.message ?? "No Last Reader")"
            } else {
                if (paymentDevice?.isConnected())! {
                    self.activeReaderLbl.text = "Connected: \((paymentDevice?.id)!)"
                    self.checkForReaderUpdate(reader: paymentDevice)
                    print("Connected automatically with device.")
                }
            }
        })
        
    }
    
    // Code that checks if there's a software update available for the connected
    // reader and initiates the process if there's one available.
    func checkForReaderUpdate(reader:PPRetailPaymentDevice?) {
        
        if(reader != nil && reader?.pendingUpdate != nil && (reader?.pendingUpdate?.isRequired)!) {
            reader?.pendingUpdate?.offer({ (error, updateComplete) in
                if(updateComplete) {
                    print("Reader update complete.")
                } else {
                    print("Error in offer step: \(error?.debugId)")
                    print("Error in offer step: \(error?.code)")
                    print("Error in offer step: \(error?.message)")
                }
            })
        } else {
            print("Reader update not required at this time.")
        }
        
    }
    
    @IBAction func showCode(_ sender: UIButton){
        
        switch sender.tag {
        case 0:
            if (findAndConnectCodeView.isHidden) {
                findAndConnectCodeBtn.setTitle("Hide Code", for: .normal)
                findAndConnectCodeView.isHidden = false
                findAndConnectCodeView.text = "deviceManager.searchAndConnect({ (error, paymentDevice) in\n" +
                    "   <code to handle success/failure>\n" +
                "})"
            } else {
                findAndConnectCodeBtn.setTitle("View Code", for: .normal)
                findAndConnectCodeView.isHidden = true
            }
        case 1:
            if (connectLastKnownCodeView.isHidden) {
                connectLastKnownCodeBtn.setTitle("Hide Code", for: .normal)
                connectLastKnownCodeView.isHidden = false
                connectLastKnownCodeView.text = "deviceManager.connect(toLastActiveReader: { (error, paymentDevice) in\n" +
                    "    <code to handle success/failure>\n" +
                "})"
            } else {
                connectLastKnownCodeBtn.setTitle("View Code", for: .normal)
                connectLastKnownCodeView.isHidden = true
            }
        case 2:
            if autoConnectReaderCodeView.isHidden {
                autoConnectReaderCodeBtn.setTitle("Hide Code", for: .normal)
                autoConnectReaderCodeView.isHidden = false
                autoConnectReaderCodeView.text = "deviceManager?.scanAndAutoConnect(toBluetoothReader: lastActiveReader, callback: { (error, paymentDevice) in\n" +
                        "<code to handle success/failure>\n}"
            } else {
                autoConnectReaderCodeBtn.setTitle("View Code", for: .normal)
                autoConnectReaderCodeView.isHidden = true
            }
        default:
            print("No Button Tag Found")
        }
    }
    
    @IBAction func goToPmtPage(_ sender: Any) {
        performSegue(withIdentifier: "goToPmtPage", sender: sender)
    }
    
}
