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
    
    override func viewDidAppear(_ animated: Bool) {

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func goToInitPage(_ sender: UIButton) {
        
        performSegue(withIdentifier: "showInitPageSegue", sender: sender)
    }


}
