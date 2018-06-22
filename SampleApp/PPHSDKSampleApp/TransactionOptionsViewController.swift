//
//  TransactionOptionsViewController.swift
//  PPHSDKSampleApp
//
//  Created by Deol, Sukhpreet(AWF) on 6/20/18.
//  Copyright © 2018 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class TransactionOptionsViewController: UIViewController {
    
    @IBOutlet weak var authCaptureSwitch: UISwitch!
    @IBOutlet weak var promptInAppSwitch: UISwitch!
    @IBOutlet weak var promptInCardReaderSwitch: UISwitch!
    @IBOutlet weak var tippingOnReaderSwitch: UISwitch!
    @IBOutlet weak var amountBasedTippingSwitch: UISwitch!
    @IBOutlet weak var tagTextField: UITextField!
    @IBOutlet var formFactorButtons: [UIButton]!
    
    var paymentViewController: PaymentViewController!
    var transactionOptions: PPRetailTransactionBeginOptions!
    var formFactorArray: [PPRetailFormFactor]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setToolBarForTextField(tagTextField)
        
        authCaptureSwitch.isOn = transactionOptions.isAuthCapture
        promptInAppSwitch.isOn = transactionOptions.showPromptInApp
        promptInCardReaderSwitch.isOn = transactionOptions.showPromptInCardReader
        tippingOnReaderSwitch.isOn = transactionOptions.tippingOnReaderEnabled
        amountBasedTippingSwitch.isOn = transactionOptions.amountBasedTipping
        
        toggleButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
    }
    
    @IBAction func authCaptureSwitchPressed(_ sender: UISwitch) {
        transactionOptions.isAuthCapture = authCaptureSwitch.isOn
        
    }
    @IBAction func promptInAppSwitchPressed(_ sender: UISwitch) {
        transactionOptions.showPromptInApp = promptInAppSwitch.isOn
    }
    
    @IBAction func promptInCardReaderSwitchPressed(_ sender: UISwitch) {
        transactionOptions.showPromptInCardReader = promptInCardReaderSwitch.isOn
    }
    
    @IBAction func tippingOnReaderSwitchPressed(_ sender: UISwitch) {
        transactionOptions.tippingOnReaderEnabled = tippingOnReaderSwitch.isOn
    }
    
    @IBAction func amountBasedTippingSwitchPressed(_ sender: UISwitch) {
        transactionOptions.amountBasedTipping = amountBasedTippingSwitch.isOn
    }
    
    @IBAction func tagTextFieldEndEditing(_ sender: UITextField) {
        transactionOptions.tag = sender.text ?? ""
    }
    
    @IBAction func formFactorButtonPressed(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        
        var formFactor: PPRetailFormFactor!
        switch sender.tag {
        case 1:
            formFactor = PPRetailFormFactor.magneticCardSwipe
        case 2:
            formFactor = PPRetailFormFactor.chip
        case 3:
            formFactor = PPRetailFormFactor.emvCertifiedContactless
        case 4:
            formFactor = PPRetailFormFactor.secureManualEntry
        case 5:
            formFactor = PPRetailFormFactor.manualCardEntry
        default:
            formFactor = PPRetailFormFactor.none
        }
        
        if sender.isSelected {
            formFactorArray.append(formFactor)
            transactionOptions.preferredFormFactors = formFactorArray
        } else {
            if let index = formFactorArray.index(of: formFactor){
                formFactorArray.remove(at: index)
                transactionOptions.preferredFormFactors = formFactorArray
            }
        }
    }
    
    @IBAction func runTransactionButtonPressed(_ sender: UIButton) {
        dismiss(animated: true) {
            self.paymentViewController.formFactorArray = self.formFactorArray
        }
    }
    
    private func toggleButtons(){
        for factor in formFactorArray {
            var tag: Int!
            switch factor {
            case PPRetailFormFactor.magneticCardSwipe :
                tag = 1
            case PPRetailFormFactor.chip:
                tag = 2
            case PPRetailFormFactor.emvCertifiedContactless:
                tag = 3
            case PPRetailFormFactor.secureManualEntry:
                tag = 4
            case PPRetailFormFactor.manualCardEntry:
                tag = 5
            default:
                tag = 0
            }
            
            for button in formFactorButtons {
                if button.tag == tag {
                    button.isSelected = true
                }
            }
        }
    }
    
    private func setToolBarForTextField(_ sender: UITextField){
        //init toolbar for keyboard
        let toolbar:UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0,  width: self.view.frame.size.width, height: 30))
        //create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissKeyboard))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()
        
        sender.inputAccessoryView = toolbar
        sender.layer.borderColor = (UIColor(red: 0/255, green: 159/255, blue: 228/255, alpha: 1)).cgColor
    }
    
    @objc private func dismissKeyboard(){
        view.endEditing(true)
    }
}
