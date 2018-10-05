//
//  OfflinePaymentCompletedViewController.swift
//  PPHSDKSampleApp
//
//  Created by Deol, Sukhpreet(AWF) on 6/25/18.
//  Copyright © 2018 cowright. All rights reserved.
//

import UIKit

class OfflinePaymentCompletedViewController: UIViewController {

    var paymentViewController: PaymentViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    /// THIS FUNCTION IS ONLY FOR UI.
    /// This takes an array of UIViewControllers that are in the current Navigation Controller stack and removes the
    /// 4th index which is this ("OfflinePaymentCompletedViewController") and replaces the PaymentViewController with
    /// a newly instantiated PaymentViewController and makes that the new Navigation Stack and pushes to that new
    /// PaymentViewController.
    /// viewController array has at index 0 : "WelcomeViewController", 1 : "InitializeViewController"
    /// 2 : "DeviceDiscoveryViewController", 3 : "PaymentViewController", 4 : "OfflinePaymentCompletedViewController"
    /// - Parameter sender: UIButton for No Sale
    @IBAction func newSaleBtnPressed(_ sender: CustomButton) {
        paymentViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PaymentViewController") as? PaymentViewController
        var viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        viewControllers.removeLast()
        viewControllers[3] = paymentViewController!
        self.navigationController?.setViewControllers(viewControllers, animated: true)

    }
    
}
