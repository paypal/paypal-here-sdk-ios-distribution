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
  
  @IBOutlet weak var findAndConnect: CustomButton!
  @IBOutlet weak var findAndConnectCodeView: UITextView!
  @IBOutlet weak var connectLastKnown: CustomButton!
  @IBOutlet weak var connectLastKnownCodeView: UITextView!
  @IBOutlet weak var activeReaderLbl: UILabel!
  @IBOutlet weak var autoConnectReader: CustomButton!
  @IBOutlet weak var autoConnectReaderCodeView: UITextView!
  @IBOutlet weak var autoConnectActivityIndicator: UIActivityIndicatorView!
  
  private var goToPaymentPageButton: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitle("Run Transactions", for: .normal)
    btn.titleLabel?.applyTheme(theme: .sansBigRegular)
    btn.backgroundColor = PPHColor.azure
    btn.setTitleColor(.white, for: .normal)
    btn.layer.cornerRadius = 24
    return btn
  }()
  
  let deviceManager = PayPalRetailSDK.deviceManager()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    setUpDefaultView()
    layoutGoToPaymentPageButton()
    // Watch for audio readers.
    // This will show a microphone connection permission prompt on the initial call (only once per app install)
    // Time this call such that it does not interfere with any other alerts
    // Requires a merchant, so start watching after a successful initializeMerchant
    // The audio reader may not be available to some merchants based on their location or other criteria
    // This is required if the app would like to use audio readers
    PayPalRetailSDK.startWatchingAudio()
  }
  
  // Function to search for connected devices and show the UI to select which
  // device to use. As part of this function, we also need to include the process
  // of reader updates for our BT readers.
  @IBAction func findAndConnectReader(_ sender: Any) {
    deviceManager?.searchAndConnect({ (error, paymentDevice) -> Void in
      if let err = error {
        print("Search Device Error: \(String(describing: err.debugId))")
        print("Search Device Error: \(String(describing: err.code))")
        print("Search Device Error: \(String(describing: err.message))")
        
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
        print("Connect Last Device Error: \(String(describing: err.debugId))")
        print("Connect Last Device Error: \(String(describing: err.code))")
        print("Connect Last Device Error: \(String(describing: err.message))")
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
    autoConnectReader.isHidden = true
    let lastActiveReader = deviceManager?.getLastActiveBluetoothReader()
    deviceManager?.scanAndAutoConnect(toBluetoothReader: lastActiveReader, callback: { (error, paymentDevice) in
      self.autoConnectActivityIndicator.stopAnimating()
      self.autoConnectReader.isHidden = false
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
          print("Error in offer step: \(String(describing: error?.debugId))")
          print("Error in offer step: \(String(describing: error?.code))")
          print("Error in offer step: \(String(describing: error?.message))")
        }
      })
    } else {
      print("Reader update not required at this time.")
    }
    
  }
  
  private func setUpDefaultView(){
    // Setting up initial aesthetics
    
    findAndConnectCodeView.text = "deviceManager.searchAndConnect({ (error, paymentDevice) in\n" +
      "   <code to handle success/failure>\n" +
      "})"
    connectLastKnownCodeView.text = "deviceManager.connect(toLastActiveReader: { (error, paymentDevice) in\n" +
      "    <code to handle success/failure>\n" +
      "})"
    autoConnectReaderCodeView.text = "deviceManager?.scanAndAutoConnect(toBluetoothReader: lastActiveReader, callback: { (error, paymentDevice) in\n" +
      "<code to handle success/failure>\n}"
    activeReaderLbl.text = ""
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }
  
  private func layoutGoToPaymentPageButton() {
    goToPaymentPageButton.addTarget(self, action: #selector(goToPaymentPage(_:)), for: .touchUpInside)
    view.addSubview(goToPaymentPageButton)
    
    goToPaymentPageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
    goToPaymentPageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
    goToPaymentPageButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24).isActive = true
    goToPaymentPageButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
  }
  
  @objc func goToPaymentPage(_ sender: Any) {
    performSegue(withIdentifier: "goToPmtTypeSelect", sender: sender)
  }
  
}
