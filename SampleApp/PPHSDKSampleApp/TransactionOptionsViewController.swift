//
//  TransactionOptionsViewController.swift
//  PPHSDKSampleApp
//
//  Created by Deol, Sukhpreet(AWF) on 6/20/18.
//  Copyright © 2018 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

protocol TransactionOptionsViewControllerDelegate: NSObjectProtocol {
    func transactionOptions(controller: TransactionOptionsViewController, formFactorArray: [PPRetailFormFactor])
}

class TransactionOptionsViewController: UIViewController {
    
    @IBOutlet weak var authCaptureSwitch: UISwitch!
    @IBOutlet weak var promptInAppSwitch: UISwitch!
    @IBOutlet weak var promptInCardReaderSwitch: UISwitch!
    @IBOutlet weak var tippingOnReaderSwitch: UISwitch!
    @IBOutlet weak var amountBasedTippingSwitch: UISwitch!
    @IBOutlet weak var tagTextField: UITextField!
    @IBOutlet var formFactorButtons: [UIButton]!
    
    /// Sets up the parameters for taking in Options from Payment View Controller
    weak var delegate: TransactionOptionsViewControllerDelegate?
    var transactionOptions: PPRetailTransactionBeginOptions!
    var formFactorArray: [PPRetailFormFactor]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Sets the toolbar to the "tagTextField"
        setToolBarForTextField(tagTextField)
        
        // Turn the switch on/off depending on the value of the option fields.
        authCaptureSwitch.isOn = transactionOptions.isAuthCapture
        promptInAppSwitch.isOn = transactionOptions.showPromptInApp
        promptInCardReaderSwitch.isOn = transactionOptions.showPromptInCardReader
        tippingOnReaderSwitch.isOn = transactionOptions.tippingOnReaderEnabled
        amountBasedTippingSwitch.isOn = transactionOptions.amountBasedTipping
        
        // Turn the formFactor button on/off depending on the formFactors selected.
        toggleButtons()
    }
    
    /// The following 5 functions are triggered when a switch is pressed and it's value is changed.
    /// Depending on the if the switch is on or off, these functions will set the appropriate option to true or false.
    /// - Parameter sender: UISwitch assoicated with the options.
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
    
    /// This function is triggered when the UITextField for Tag is doneEditing
    /// It will take the text in the UITextField and set it to the transactionOptions.tag field.
    /// If nothing is typed in the field then it will pass an empty value to the field.
    /// - Parameter sender: UITextField for the Tag Field.
    @IBAction func tagTextFieldEndEditing(_ sender: UITextField) {
        transactionOptions.tag = sender.text ?? ""
    }
    
    /// This function will be triggred when one of the formFactor buttons is pressed. Whichever button triggers this
    /// function, this function will get the associated formFactor and append the formFactor to the formFactorArray if
    /// the formFactor isSelected and remove the formFactor from the array if the formFactor was removed(clicked on again).
    /// - Parameter sender: UIButton assoicated with the formFactor Buttons.
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
    
    /// This function will pass the formFactorArray to the previous ViewController (PaymentViewController)
    /// and dismiss the transactionOptionsViewController. This event is
    /// triggered by the "runTransactionButton" at the bottom of the screen.
    /// - Parameter sender: The UIButton associated with the IBAction
    @IBAction func runTransactionButtonPressed(_ sender: UIButton) {
        self.delegate?.transactionOptions(controller: self,formFactorArray: self.formFactorArray)
        dismiss(animated: true, completion: nil)
    }
    
    /// THIS FUNCTION IS ONLY FOR UI. This will iterate through the formFactorArray and get the appropriate tag for the
    /// buttons depending on the formFactor that are in the array. Then it will go through UIButton Outlet Collection
    /// Array and set the isSelected State for the buttons associated with the form Factor.
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
    
    /// THIS FUNCTION IS ONLY FOR UI. This function will create a toolbar which will have a "Done" button
    /// to let us know that we have finished editing.
    /// - Parameter sender: UITextfield that we want to add the toolbar to
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
    
    /// THIS FUNCTION IS ONLY FOR UI. It will end keyboard editing and is the action for the done button in the
    /// UITextfield toolbar.
    @objc private func dismissKeyboard(){
        view.endEditing(true)
    }
}
