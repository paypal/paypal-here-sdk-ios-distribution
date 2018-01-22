//
//  InitializeViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 11/16/16.
//  Copyright © 2016 cowright. All rights reserved.
//

import UIKit
import SafariServices
import PayPalRetailSDK

// Set up the notification name which will receive the token from the sample server
let kCloseSafariViewControllerNotification = "kCloseSafariViewControllerNotification"

class InitializeViewController: UIViewController, SFSafariViewControllerDelegate {

    
    @IBOutlet weak var demoAppLbl: UILabel!
    @IBOutlet weak var initSdkButton: UIButton!
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
    @IBOutlet weak var connectCardReaderBtn: UIButton!
    
    var svc: SFSafariViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setting up initial aesthetics.
        demoAppLbl.font = UIFont.boldSystemFont(ofSize: 16.0)
        merchInfoView.isHidden = true
        initSdkCode.isHidden = true
        initMerchCode.isHidden = true
        initMerchantButton.isEnabled = false
        connectCardReaderBtn.isHidden = true
        
        // Receive the notification that the token is being returned
        NotificationCenter.default.addObserver(self, selector: #selector(setupMerchant(notification:)), name: NSNotification.Name(rawValue: kCloseSafariViewControllerNotification), object: nil)

    }
    
    override func viewDidAppear(_ animated: Bool) {

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    @IBAction func initSDK(_ sender: UIButton) {
        
        initMerchantButton.isEnabled = true
        
        // First things first, we need to initilize the SDK itself.
        PayPalRetailSDK.initializeSDK()
        
        initSdkButton.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .disabled)
        initSdkButton.isEnabled = false
    }
    
    @IBAction func initSdkInfo(_ sender: UIButton) {

        if (initSdkCode.isHidden) {
            initSdkInfoBtn.setTitle("Hide Code", for: .normal)
            initSdkCode.isHidden = false
            initSdkCode.text = "PayPalRetailSDK.initializeSDK()"
        } else {
            initSdkInfoBtn.setTitle("View Code", for: .normal)
            initSdkCode.isHidden = true
        }
        
    }
    
    func performLogin() {
        // Set your URL for your backend server that handles OAuth.  This sample uses an instance of the
        // sample retail node server that's available at https://github.com/paypal/paypal-retail-node. To
        // set this to Live, simply change /sandbox to /live.  The returnTokenOnQueryString value tells
        // the sample server to return the actual token values instead of the compositeToken
        let url = NSURL(string: "http://pphsdk2oauthserver.herokuapp.com/toPayPal/" + envSelector.titleForSegment(at: envSelector.selectedSegmentIndex)! + "?returnTokenOnQueryString=true")
        
        // Check if there's a previous token saved in UserDefaults and, if so, use that.  This will also
        // check that the saved token matches the environment.  Otherwise, kick open the
        // SFSafariViewController to expose the login and obtain another token.
        let tokenDefault = UserDefaults.init()

        if((tokenDefault.string(forKey: "ACCESS_TOKEN") != nil) && (envSelector.titleForSegment(at: envSelector.selectedSegmentIndex)! == tokenDefault.string(forKey: "ENVIRONMENT"))) {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: kCloseSafariViewControllerNotification), object: tokenDefault.string(forKey: "ACCESS_TOKEN"))
        } else {
            // Present a SFSafariViewController to handle the login to get the merchant account to use.
            let svc = SFSafariViewController(url: url! as URL)
            svc.delegate = self
            self.present(svc, animated: true, completion: nil)
        }
    }
    
    
    @IBAction func initMerchant(_ sender: UIButton) {
        
        envSelector.isEnabled = false
        activitySpinner.startAnimating()

        performLogin()
        
    }
    
    func setupMerchant(notification: NSNotification) {
        
        // Dismiss the SFSafariViewController when the notification of token has been received.
        self.presentedViewController?.dismiss(animated: true, completion: { 
            print("successful dismissal")
        })
        
        // Grab the token(s) from the notification and pass it into the merchant initialize call to set up
        // the merchant.  Upon successful initialization, the 'Connect Card Reader' button will be
        // enabled for use.
        let accessToken = notification.object as! String

        let tokenDefault = UserDefaults.init()
        let sdkCreds = SdkCredential.init()
        sdkCreds.accessToken = accessToken
        sdkCreds.refreshUrl = tokenDefault.string(forKey: "REFRESH_URL")
        sdkCreds.environment = tokenDefault.string(forKey: "ENVIRONMENT")
        sdkCreds.repository = "production"
    
        PayPalRetailSDK.initializeMerchant(withCredentials: sdkCreds) { (error, merchant) in
            if let err = error {
                self.activitySpinner.stopAnimating()
                print("Debug ID: \(err.debugId)")
                print("Error Message: \(err.message)")
                print("Error Code: \(err.code)")

                // The token did not work, so clear the saved token so we can go back to the login page
                let tokenDefault = UserDefaults.init()
                tokenDefault.removeObject(forKey: "ACCESS_TOKEN")
                self.performLogin()
            }

            print("Merchant Success!")
            self.activitySpinner.stopAnimating()
            self.initMerchantButton.setImage(#imageLiteral(resourceName: "small-greenarrow"), for: .disabled)
            self.initMerchantButton.isEnabled = false
            self.merchInfoView.isHidden = false
            self.merchEmailLabel.text = merchant!.emailAddress

            // Save currency to UserDefaults for further usage. This needs to be used to initialize
            // the PPRetailInvoice for the payment later on. This app is using UserDefault but
            // it could just as easily be passed through the segue.
            let tokenDefault = UserDefaults.init()
            tokenDefault.setValue(merchant!.currency, forKey: "MERCH_CURRENCY")

            // Add the BN code for Partner tracking. To obtain this value, contact
            // your PayPal account representative. Please do not change this value when
            // using this sample app for testing.
            merchant?.referrerCode = "PPHSDK_SampleApp_iOS"

            //Enable the connect card reader button here
            self.connectCardReaderBtn.isHidden = false
        }
        
    }
    
    
    @IBAction func initMerchInfo(_ sender: UIButton) {
        
        if (initMerchCode.isHidden) {
            initMerchInfoBtn.setTitle("Hide Code", for: .normal)
            initMerchCode.isHidden = false
            initMerchCode.text = "PayPalRetailSDK.initializeMerchant(sdkToken) { (error, merchant) -> Void in \n" +
                "     <code to handle success/failure>\n" +
                "})"
        } else {
            initMerchInfoBtn.setTitle("View Code", for: .normal)
            initMerchCode.isHidden = true
            if((merchEmailLabel.text) != "") {
                merchInfoView.isHidden = false
            }
            
        }
 
    }
    
    @IBAction func logout(_ sender: UIButton) {
        
        // Clear out the UserDefaults and show the appropriate buttons/labels
        let tokenDefault = UserDefaults.init()
        tokenDefault.removeObject(forKey: "ACCESS_TOKEN")
        tokenDefault.removeObject(forKey: "MERCH_CURRENCY")
        tokenDefault.synchronize()
        
        merchEmailLabel.text = ""
        merchInfoView.isHidden = true
        initMerchantButton.isEnabled = true
        initMerchantButton.setImage(#imageLiteral(resourceName: "small-bluearrow"), for: .normal)
        envSelector.isEnabled = true
        connectCardReaderBtn.isHidden = true
    }

    
    @IBAction func goToDeviceDiscovery(_ sender: Any) {
        performSegue(withIdentifier: "showDeviceDiscovery", sender: sender)
    }
    
    
    // This function would be called if the user pressed the Done button inside the SFSafariViewController.
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
        activitySpinner.stopAnimating()
        initMerchantButton.isEnabled = true
        envSelector.isEnabled = true
        
    }


}

