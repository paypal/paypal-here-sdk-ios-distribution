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
    configureNavigationController()
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.navigationBar.isHidden = false
  }
  
  private func configureNavigationController() {
    navigationController?.navigationBar.isHidden = true
    navigationController?.navigationBar.tintColor = .darkGray
    navigationController?.navigationBar.backIndicatorImage = #imageLiteral(resourceName: "Close")
    navigationController?.navigationBar.backIndicatorTransitionMaskImage = #imageLiteral(resourceName: "Close")
    navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }
  
  @IBAction func goToInitPage(_ sender: UIButton) {
    performSegue(withIdentifier: "showInitPageSegue", sender: sender)
  }
}
