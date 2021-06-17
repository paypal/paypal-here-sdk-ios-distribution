//
//  WelcomeViewController.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 3/13/17.
//  Copyright © 2017 cowright. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
  private var imgView: UIImageView = {
    let imgView = UIImageView()
    imgView.translatesAutoresizingMaskIntoConstraints = false
    imgView.image = UIImage(named: "PPHere-Logo")
    imgView.contentMode = .scaleToFill
    return imgView
  }()
  
  private var sdkVersionLabel: UILabel = {
    let lbl = UILabel()
    lbl.translatesAutoresizingMaskIntoConstraints = false
    lbl.textAlignment = .center
    lbl.text = "SDK v2.x"
    lbl.applyTheme(theme: .sansBigLight)
    return lbl
  }()
  
  private var demoAppLabel: UILabel = {
    let lbl = UILabel()
    lbl.translatesAutoresizingMaskIntoConstraints = false
    lbl.textAlignment = .center
    lbl.text = "Demo App"
    lbl.applyTheme(theme: .sansBigLight)
    return lbl
  }()
  
  private var getStartedButton: UIButton = {
    let btn = UIButton()
    btn.translatesAutoresizingMaskIntoConstraints = false
    btn.setTitle("Get Started", for: .normal)
    btn.titleLabel?.applyTheme(theme: .sansBigRegular)
    btn.backgroundColor = PPHColor.azure
    btn.setTitleColor(.white, for: .normal)
    btn.layer.cornerRadius = 24
    return btn
  }()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    layoutImgView()
    layoutSDKVersionLabel()
    layoutDemoAppLabel()
    layoutGetStartedButton()
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
  
  private func layoutImgView() {
    view.addSubview(imgView)

    imgView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    imgView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    imgView.heightAnchor.constraint(equalToConstant: 175).isActive = true
  }
  
  private func layoutSDKVersionLabel() {
    view.addSubview(sdkVersionLabel)
    
    sdkVersionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
    sdkVersionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
    sdkVersionLabel.topAnchor.constraint(equalTo: imgView.bottomAnchor, constant: 4).isActive = true
  }
  
  private func layoutDemoAppLabel() {
    view.addSubview(demoAppLabel)
    
    demoAppLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8).isActive = true
    demoAppLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8).isActive = true
    demoAppLabel.topAnchor.constraint(equalTo: sdkVersionLabel.bottomAnchor, constant: 4).isActive = true
    demoAppLabel.heightAnchor.constraint(equalToConstant: 24).isActive = true
  }
  
  private func layoutGetStartedButton() {
    getStartedButton.addTarget(self, action: #selector(goToInitPage(_:)), for: .touchUpInside)
    view.addSubview(getStartedButton)
    
    getStartedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
    getStartedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
    getStartedButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -24).isActive = true
    getStartedButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
  }
  
  @objc func goToInitPage(_ sender: UIButton) {
    performSegue(withIdentifier: "showInitPageSegue", sender: sender)
  }
}
