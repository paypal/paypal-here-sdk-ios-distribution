//
//  MerchantSettingsController.swift
//  PPHSDKSampleApp
//
//  Created by Priyank Shah on 3/10/21.
//  Copyright © 2021 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK


class MerchantSettingsController: UIViewController {
    var merchant: PPRetailMerchant!
    
    @IBOutlet weak var txtsoftDescriptor: UITextField!
    @IBOutlet weak var txtStoreId: UITextField!
    @IBOutlet weak var txtreferrerCode: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Merchant Settings"
        showMerchantDetails()
    }
    
    func showMerchantDetails() {
        if let softDescriptor = merchant.softDescriptor {
            txtsoftDescriptor.text = softDescriptor
        }
        if let storeID = merchant.storeId {
            txtStoreId.text = storeID
        }
        if let referrerCode = merchant.referrerCode {
            txtreferrerCode.text = referrerCode
        }
    }
    
    @IBAction func updateMerchantHandler() {
        if let merchant = self.merchant {
            if let softDescriptor = txtsoftDescriptor.text {
                merchant.softDescriptor = softDescriptor
            }
            if let storeID = txtStoreId.text {
                merchant.storeId = storeID
            }
            if let referrerCode = txtreferrerCode.text {
                merchant.referrerCode = referrerCode
            }
            
            let alertController = UIAlertController(title: "Success", message: "Merchant Details have been updated", preferredStyle: .alert)
            let action = UIAlertAction(title: "OK", style: .default) { (_) in
                self.navigationController?.popViewController(animated: true)
            }
            alertController.addAction(action)
            self.present(alertController, animated: true, completion: nil)
        }
        
    }
    
    
    
    
}
