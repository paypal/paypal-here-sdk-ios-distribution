//
//  WelcomeViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 3/13/17.
//  Copyright © 2017 cowright. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {

    @IBOutlet weak var goToInitPage: UIButton!
    

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        self.navigationController?.navigationBar.tintColor = .darkGray
        self.navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "Close")
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "Close")
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func goToInitPage(_ sender: UIButton) {
        
        performSegue(withIdentifier: "showInitPageSegue", sender: sender)
    }


}
