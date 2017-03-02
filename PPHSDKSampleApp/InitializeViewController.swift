//
//  InitializeViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 11/16/16.
//  Copyright © 2016 cowright. All rights reserved.
//

import UIKit
import SafariServices

// Set up the notification name which will receive the token from the sample server
let kCloseSafariViewControllerNotification = "kCloseSafariViewControllerNotification"

class InitializeViewController: UIViewController, SFSafariViewControllerDelegate {

    @IBOutlet weak var initSdkButton: UIButton!
    @IBOutlet weak var initMerchantButton: UIButton!
    @IBOutlet weak var merchAcctLabel: UILabel!
    @IBOutlet weak var merchEmailLabel: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var successOrFail: UILabel!
    @IBOutlet weak var logoutBtn: UIButton!
    
    
    var svc: SFSafariViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initSdkButton.isHidden = false
        initMerchantButton.isHidden = true
        merchAcctLabel.isHidden = true
        merchEmailLabel.isHidden = true
        successOrFail.isHidden = true
        logoutBtn.isHidden = true
        
        // Upon initial load, disable the Payments tab bar.  This is re-enabled once the merchant
        // is initialized.
        if let arrayOfTabBarItems = tabBarController?.tabBar.items as AnyObject as? NSArray, let tabBarItem = arrayOfTabBarItems[1] as? UITabBarItem {
            tabBarItem.isEnabled = false
        }
        
        // Receive the notification that the token is being returned
        NotificationCenter.default.addObserver(self, selector: #selector(setupMerchant(notification:)), name: NSNotification.Name(rawValue: kCloseSafariViewControllerNotification), object: nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func initSDK(_ sender: UIButton) {
        
        initSdkButton.isHidden = true
        initMerchantButton.isHidden = false
        initMerchantButton.sizeToFit()
        
        // First things first, we need to initilize the SDK itself.
        PayPalRetailSDK.initializeSDK()
        
        // Set up a device discovered listener for EMV device connection.  If a software update is required
        // then we'll offer up that flow.
        PayPalRetailSDK.addDeviceDiscoveredListener { (device) -> Void in
            device!.addUpdateRequiredListener({ (deviceUpdate) -> Void in
                if(deviceUpdate!.isRequired) {
                    deviceUpdate!.offer({ (error, status) -> Void in
                        if((error) != nil) {
                            print("Error: \(error!.description)")
                        } else {
                            deviceUpdate!.begin(true, callback: { (upgradeError, upgradeStatus) -> Void in
                                if((upgradeError) != nil) {
                                    print("Error: \(upgradeError!.description)")
                                } else {
                                    print("Update status: \(upgradeStatus)")
                                }
                            })
                        }
                    })
                } else {
                    print("Update not a required update")
                }
            })
        }
        
    }
    
    @IBAction func initMerchant(_ sender: UIButton) {
        
        initMerchantButton.isHidden = true
        successOrFail.isHidden = true
        activitySpinner.startAnimating()

        // Set your URL for your backend server that handles OAuth.  This sample uses and instance of the
        // sample retail node server that's available at https://github.com/paypal/paypal-retail-node. To
        // set this to Live, simply change /sandbox to /live.
        let url = NSURL(string: "http://pphsdk2oauthserver.herokuapp.com/toPayPal/sandbox")
        
        // Check if there's a previous token saved in UserDefaults and, if so, use that.  This will also
        // check that the saved token matches the environment.  Otherwise, kick open the
        // SFSafariViewController to expose the login and obtain another token.
        let tokenDefault = UserDefaults.init()
        let savedToken = tokenDefault.string(forKey: "SAVED_TOKEN")
        let env = savedToken?.components(separatedBy: ":")

        if((savedToken != nil) && url!.absoluteString!.contains(env![0])) {
            
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kCloseSafariViewControllerNotification), object: savedToken)
            
        } else {
            
            // Present a SFSafariViewController to handle the login to get the merchant account to use.
            let svc = SFSafariViewController(url: url as! URL)
            svc.delegate = self
            self.present(svc, animated: true, completion: nil)
        }
        
        
    }
    
    func setupMerchant(notification: NSNotification) {
        
        // Dismiss the SFSafariViewController when the notification of token has been received.
        self.presentedViewController?.dismiss(animated: true, completion: { 
            print("successful dismissal")
        })
        
        // Grab the token from the notification and pass it into the merchant initialize call to set up
        // the merchant.  Upon successful initialization, the payments & refunds tab will be enabled for use.
        let sdkToken = notification.object as! String
        
        PayPalRetailSDK.initializeMerchant(sdkToken, completionHandler: {(error, merchant) -> Void in
            
            if let err = error {
                self.activitySpinner.stopAnimating()
                self.successOrFail.isHidden = false
                self.successOrFail.text = "Failed! Check logs for error"
                self.successOrFail.adjustsFontSizeToFitWidth = true
                self.successOrFail.textAlignment = .center
                self.initMerchantButton?.isHidden = false
                print("Debug ID: \(err.debugId)")
                print("Error Message: \(err.message)")
                
                return
            }
            
            // TODO: add validation for merchant status (enabled for PPH) when/if it's avail in the SDK
            
            print("Merchant Success!")
            self.activitySpinner.stopAnimating()
            self.successOrFail.isHidden = false
            self.successOrFail.text = "Success! Merchant Initialized"
            self.successOrFail.adjustsFontSizeToFitWidth = true
            self.successOrFail.textAlignment = .center
            self.merchAcctLabel.isHidden = false
            self.merchEmailLabel.isHidden = false
            self.merchEmailLabel.text = merchant!.emailAddress
            self.merchEmailLabel.adjustsFontSizeToFitWidth = true
            self.merchEmailLabel.textAlignment = .center
            self.merchEmailLabel.numberOfLines = 0
            self.merchEmailLabel.sizeToFit()
            self.logoutBtn.isHidden = false
            
            // Save currency to UserDefaults for further usage
            let tokenDefault = UserDefaults.init()
            tokenDefault.setValue(merchant!.currency, forKey: "MERCH_CURRENCY")
            
            // Code to re-enable the payments/refunds tab bar item
            if let arrayOfTabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray, let tabBarItem = arrayOfTabBarItems[1] as? UITabBarItem {
                tabBarItem.isEnabled = true
            }
            
        })
    }
    
    @IBAction func logout(_ sender: UIButton) {
        
        // Clear out the UserDefaults and show the appropriate buttons/labels
        let tokenDefault = UserDefaults.init()
        tokenDefault.removeObject(forKey: "SAVED_TOKEN")
        tokenDefault.removeObject(forKey: "MERCH_CURRENCY")
        tokenDefault.synchronize()
        
        merchAcctLabel.isHidden = true
        merchEmailLabel.isHidden = true
        successOrFail.isHidden = true
        logoutBtn.isHidden = true
        
        // Code to disable the payments/refunds tab bar item
        if let arrayOfTabBarItems = self.tabBarController?.tabBar.items as AnyObject as? NSArray, let tabBarItem = arrayOfTabBarItems[1] as? UITabBarItem {
            tabBarItem.isEnabled = false

        }
        
        initMerchantButton.isHidden = false
        initMerchantButton.sizeToFit()
    }
    
    // This function would be called if the user pressed the Done button inside the SFSafariViewController.
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        activitySpinner.stopAnimating()
        initMerchantButton.isHidden = false
        initMerchantButton.sizeToFit()
        
    }
    

}

