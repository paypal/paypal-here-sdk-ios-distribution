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
    
    let device = PPRetailDeviceManager.init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting up initial aesthetics
        findAndConnectCodeView.isHidden = true
        connectLastKnownCodeView.isHidden = true
        goToPmtPageBtn.isHidden = true
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let window = UIApplication.shared.keyWindow
        window?.rootViewController = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Function to search for connected devices and show the UI to select which
    // device to use. As part of this function, we also need to include the process
    // of reader updates for our BT readers.
    @IBAction func findAndConnectReader(_ sender: Any) {
        device?.searchAndConnect(ui: { (error, paymentDevice) -> Void in
            if let err = error {
                print("Search Device Error: \(err.debugId)")
                print("Search Device Error: \(err.code)")
                print("Search Device Error: \(err.developerMessage)")
            }
            self.device?.setActiveReader(paymentDevice)
        })
        if((device?.getActiveReader()?.pendingUpdate) != nil) {
            checkForReaderUpdate()
        }
    }
    
    // Function to connect to the last known reader device used and check for any
    // reader updates.
    @IBAction func connectToLastReader(_ sender: Any) {
        device?.connectToLastActiveReaderOrFindAnother(ui: { (error, paymentDevice) -> Void in
            if let err = error {
                print("Connect Last Device Error: \(err.debugId)")
                print("Connect Last Device Error: \(err.code)")
                print("Connect Last Device Error: \(err.developerMessage)")
            }
            self.device?.setActiveReader(paymentDevice)
        })
        if((device?.getActiveReader()?.pendingUpdate) != nil) {
            checkForReaderUpdate()
        }
    }
    
    // Code that checks if there's a software update available for the connected
    // reader and initiates the process if there's one available.
    func checkForReaderUpdate() {
        device?.getActiveReader()?.addUpdateRequiredListener({ (update) -> Void in
            if(update?.isRequired)! {
                update?.offer({ (error, startUpdate) in
                    if(startUpdate) {
                        update?.begin({ (error, updateComplete) in
                            if(updateComplete) {
                                print("Reader update complete.")
                            } else {
                                print("Reader Update Error: \(error?.debugId)")
                                print("Reader Update Error: \(error?.code)")
                                print("Reader Update Error: \(error?.developerMessage)")
                            }
                        })
                    } else {
                        print("Error in offer step: \(error?.debugId)")
                        print("Error in offer step: \(error?.code)")
                        print("Error in offer step: \(error?.developerMessage)")
                    }
                })
            } else {
                print("Reader update not required at this time.")
            }
        })
        
        goToPmtPageBtn.isHidden = false
    }
    
    @IBAction func showCode(_ sender: UIButton){
        
        switch sender.tag {
        case 0:
            if (findAndConnectCodeView.isHidden) {
                findAndConnectCodeBtn.setTitle("Hide Code", for: .normal)
                findAndConnectCodeView.isHidden = false
                findAndConnectCodeView.text = "device.searchAndConnect(ui: { (error, paymentDevice) in\n" +
                                              "     // code to handle failure or\n" +
                                              "     // set active reader on success\n" +
                                              "})"
            } else {
                findAndConnectCodeBtn.setTitle("View Code", for: .normal)
                findAndConnectCodeView.isHidden = true
            }
        case 1:
            if (connectLastKnownCodeView.isHidden) {
                connectLastKnownCodeBtn.setTitle("Hide Code", for: .normal)
                connectLastKnownCodeView.isHidden = false
                connectLastKnownCodeView.text = "device.connectToLastActiveReaderOrFindAnother(ui: { (error, paymentDevice) in\n" +
                                                "     // code to handle failure or\n" +
                                                "     // set active reader on success\n" +
                                                "})"
            } else {
                connectLastKnownCodeBtn.setTitle("View Code", for: .normal)
                connectLastKnownCodeView.isHidden = true
            }
        default:
            print("No Button Tag Found")
        }
        
    }
    
    @IBAction func goToPmtPage(_ sender: Any) {
        performSegue(withIdentifier: "goToPmtPage", sender: sender)
    }
    
}
