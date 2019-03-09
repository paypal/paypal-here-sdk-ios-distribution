//
//  WebKitViewController.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/17/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit
import WebKit
import PayPalRetailSDK

protocol WebKitViewControllerDelegate: NSObjectProtocol {
    func returnURL(controller: WebKitViewController, returnUrl: String)
}

class WebKitViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    
    var webView: WKWebView!
    weak var delegate: WebKitViewControllerDelegate?
    var url: URL!
    private var returnUrl: String = ""
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        webView.uiDelegate = self
        view = webView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.title = "Braintree Login"
        self.navigationController?.navigationBar.barTintColor = UIColor.white
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verifyUrl(url)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.delegate?.returnURL(controller: self, returnUrl: self.returnUrl)
    }
    
    func verifyUrl(_ url: URL){
        if url.absoluteString != "" {
            openWebKit(with: url)
        } else {
            let alert = UIAlertController(title: "URL is empty", message: "", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) { [unowned self] (_) in
                self.navigationController?.popViewController(animated: true)
            }
            alert.addAction(okAction)
            self.present(alert, animated: true)
        }
    }
    
    func openWebKit(with url: URL){
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if (navigationAction.request.url != nil){
            let url = navigationAction.request.url?.absoluteString
            if (PayPalRetailSDK.braintreeManager()!.isBtReturnUrlValid(url)){
                self.returnUrl = url!
                decisionHandler(.cancel)
                dismissWebKit()
                return
            }
            decisionHandler(.allow)
        }
    }
    
    func dismissWebKit(){
        DispatchQueue.main.async {
            self.navigationController?.popViewController(animated: true)
        }
    }
}
