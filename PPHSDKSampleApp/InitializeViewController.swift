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
    @IBOutlet weak var initSdkLbl: UILabel!
    @IBOutlet weak var initMerchantButton: UIButton!
    @IBOutlet weak var merchAcctLabel: UILabel!
    @IBOutlet weak var merchEmailLabel: UILabel!
    @IBOutlet weak var activitySpinner: UIActivityIndicatorView!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var initSdkInfoBtn: UIButton!
    @IBOutlet weak var initMerchInfoBtn: UIButton!
    @IBOutlet weak var envSelector: UISegmentedControl!
    @IBOutlet weak var initMerchCode: UITextView!
    @IBOutlet weak var initSdkCode: UITextView!
    @IBOutlet weak var merchInfoView: UIView!
    @IBOutlet weak var initMerchLbl: UILabel!
    @IBOutlet weak var goToPmtPageBtn: UIButton!
    
    var svc: SFSafariViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        scrollView.contentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height)
        
        merchInfoView.isHidden = true
        initSdkCode.isHidden = true
        initMerchCode.isHidden = true
        initMerchInfoBtn.isEnabled = false
        initMerchLbl.isEnabled = false
        initMerchantButton.isHidden = true
        goToPmtPageBtn.isHidden = true
        
        initSdkCode.textContainerInset = UIEdgeInsetsMake(5, 65, 5, 5)
        initMerchCode.textContainerInset = UIEdgeInsetsMake(5, 65, 5, 5)
        
        // Receive the notification that the token is being returned
        NotificationCenter.default.addObserver(self, selector: #selector(setupMerchant(notification:)), name: NSNotification.Name(rawValue: kCloseSafariViewControllerNotification), object: nil)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let window = UIApplication.shared.keyWindow
        window?.rootViewController = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    @IBAction func initSDK(_ sender: UIButton) {
        
        initMerchLbl.isEnabled = true
        initMerchantButton.isHidden = false
        initMerchInfoBtn.isEnabled = true
        
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
        
        initSdkButton.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .normal)
        initSdkButton.isUserInteractionEnabled = false
        initSdkLbl.isEnabled = false
    }
    
    @IBAction func initSdkInfo(_ sender: UIButton) {

        if (initSdkCode.isHidden) {
            initSdkCode.isHidden = false
            initSdkCode.text = "PayPalRetailSDK.initializeSDK()"
        } else {
            initSdkCode.isHidden = true
        }
        
    }
    
    
    @IBAction func initMerchant(_ sender: UIButton) {
        
        envSelector.isEnabled = false
        initMerchantButton.isHidden = true
        activitySpinner.startAnimating()

        // Set your URL for your backend server that handles OAuth.  This sample uses and instance of the
        // sample retail node server that's available at https://github.com/paypal/paypal-retail-node. To
        // set this to Live, simply change /sandbox to /live.
        let url = NSURL(string: "http://pphsdk2oauthserver.herokuapp.com/toPayPal/" + envSelector.titleForSegment(at: envSelector.selectedSegmentIndex)!)

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
                self.initMerchantButton.isHidden = false
                print("Debug ID: \(err.debugId)")
                print("Error Message: \(err.message)")
                // TODO: need to do something with the error here
                return
            }
            
            // TODO: add validation for merchant status (enabled for PPH) when/if it's avail in the SDK
            
            print("Merchant Success!")
            self.activitySpinner.stopAnimating()
            self.initMerchantButton.isHidden = false
            self.initMerchantButton.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .normal)
            self.initMerchantButton.isUserInteractionEnabled = false
            self.initMerchLbl.isEnabled = false
            self.merchInfoView.isHidden = false
            self.merchEmailLabel.text = merchant!.emailAddress
            
            // Save currency to UserDefaults for further usage
            let tokenDefault = UserDefaults.init()
            tokenDefault.setValue(merchant!.currency, forKey: "MERCH_CURRENCY")
            
            //Enable the run transaction button here
            self.goToPmtPageBtn.isHidden = false
            
        })
    }
    
    
    @IBAction func initMerchInfo(_ sender: UIButton) {
        
        if (initMerchCode.isHidden) {
            if (!merchInfoView.isHidden) {
                merchInfoView.isHidden = true
            }
            
            initMerchCode.isHidden = false
            initMerchCode.text = "PayPalRetailSDK.initializeMerchant(sdkToken, completionHandler: {(error, merchant) -> Void in \n" +
                "     <code to handle success/failure>\n" +
                "})"
        } else {
            initMerchCode.isHidden = true
            
            if((merchEmailLabel.text) != "") {
                merchInfoView.isHidden = false
            }
            
        }
 
    }
    
    @IBAction func logout(_ sender: UIButton) {
        
        // Clear out the UserDefaults and show the appropriate buttons/labels
        let tokenDefault = UserDefaults.init()
        tokenDefault.removeObject(forKey: "SAVED_TOKEN")
        tokenDefault.removeObject(forKey: "MERCH_CURRENCY")
        tokenDefault.synchronize()
        
        merchEmailLabel.text = ""
        merchInfoView.isHidden = true
        initMerchLbl.isEnabled = true
        initMerchantButton.isUserInteractionEnabled = true
        initMerchantButton.setImage(#imageLiteral(resourceName: "small-bluearrow"), for: .normal)
        envSelector.isEnabled = true
        goToPmtPageBtn.isHidden = true
    }
    
    @IBAction func goToPmtPage(_ sender: UIButton) {
        
        performSegue(withIdentifier: "showTxnPgSegue", sender: sender)
    }
    
    // This function would be called if the user pressed the Done button inside the SFSafariViewController.
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        activitySpinner.stopAnimating()
        initMerchantButton.isHidden = false
        initMerchantButton.sizeToFit()
        initMerchInfoBtn.isHidden = false
        envSelector.isHidden = false
        
    }
    

}

