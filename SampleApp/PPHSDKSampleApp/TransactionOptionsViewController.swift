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
    func transactionOptions(controller: TransactionOptionsViewController, options: PPRetailTransactionBeginOptions)
    func transactionOptionsFormFactors(controller: TransactionOptionsViewController, formFactors: [PPRetailFormFactor]!)
}

class TransactionOptionsViewController: UIViewController {
    
    @IBOutlet weak var transactionsTableView: UITableView!
    
    /// Sets up the parameters for taking in Options from Payment View Controller
    weak var delegate: TransactionOptionsViewControllerDelegate?
    var transactionOptions: PPRetailTransactionBeginOptions!
    var formFactorArray: [PPRetailFormFactor]!
    var transactionOptionsArray = ["Sales Options", "Auth/Capture", "Prompt in App", "Prompt in Card Reader", "Tipping on Reader", "AmountBased Tipping", "Enable Quick Chip", "Enable QRC Prompt", "Tags", "Allowed Card Readers", "Magnetic Card Swipe", "Chip", "Contactless", "Secure Manual Entry", "Manual Card Entry"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Sets the toolbar to the "tagTextField"
        // setToolBarForTextField(tagTextField)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        /// This will pass the formFactorArray to the previous ViewController (PaymentViewController)
        /// and dismiss the transactionOptionsViewController.
        self.delegate?.transactionOptions(controller: self, options: transactionOptions)
        self.delegate?.transactionOptionsFormFactors(controller: self, formFactors: formFactorArray)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @objc func switchHandler(_ sender: UISwitch) {
        var formFactor: PPRetailFormFactor!
        switch sender.tag {
        case 1:
            transactionOptions.isAuthCapture = sender.isOn
        case 2:
            transactionOptions.showPromptInApp = sender.isOn
        case 3:
            transactionOptions.showPromptInCardReader = sender.isOn
        case 4:
            transactionOptions.tippingOnReaderEnabled = sender.isOn
        case 5:
            transactionOptions.amountBasedTipping = sender.isOn
        case 6:
            transactionOptions.quickChipEnabled = sender.isOn
        case 7:
            transactionOptions.qrcPromptEnabled = sender.isOn
        default:
            formFactorSwitchPressed(sender)
        }
    }
    
    
    
    /// This function is triggered when the UITextField for Tag is doneEditing
    /// It will take the text in the UITextField and set it to the transactionOptions.tag field.
    /// If nothing is typed in the field then it will pass an empty value to the field.
    /// - Parameter sender: UITextField for the Tag Field.
    @IBAction func tagTextFieldEndEditing(_ sender: UITextField) {
        transactionOptions.tag = sender.text ?? ""
    }

    /// This function will be triggered when one of the formFactor buttons is pressed. Whichever button triggers this
    /// function, this function will get the associated formFactor and append the formFactor to the formFactorArray if
    /// the formFactor isSelected and remove the formFactor from the array if the formFactor was removed(clicked on again).
    /// - Parameter sender: UIButton assoicated with the formFactor Buttons.
    @IBAction func formFactorSwitchPressed(_ sender: UISwitch) {

        var formFactor: PPRetailFormFactor!
        switch sender.tag {
        case 10:
            formFactor = PPRetailFormFactor.magneticCardSwipe
        case 11:
            formFactor = PPRetailFormFactor.chip
        case 12:
            formFactor = PPRetailFormFactor.emvCertifiedContactless
        case 13:
            formFactor = PPRetailFormFactor.secureManualEntry
        case 14:
            formFactor = PPRetailFormFactor.manualCardEntry
        default:
            formFactor = PPRetailFormFactor.none
        }

        if sender.isOn {
            formFactorArray.append(formFactor)
            transactionOptions.preferredFormFactors = formFactorArray
        } else {
            if let index = formFactorArray.index(where: { $0 == formFactor }) {
                formFactorArray.remove(at: index)
                transactionOptions.preferredFormFactors = formFactorArray
            }
        }
    }

    /// THIS FUNCTION IS ONLY FOR UI. This will iterate through the formFactorArray and get the appropriate tag for the
    /// buttons depending on the formFactor that are in the array. Then it will go through UIButton Outlet Collection
    /// Array and set the isSelected State for the buttons associated with the form Factor.
    private func toggleFormFactorSwitches() {
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
        }
    }

    /// THIS FUNCTION IS ONLY FOR UI. This function will create a toolbar which will have a "Done" button
    /// to let us know that we have finished editing.
    /// - Parameter sender: UITextfield that we want to add the toolbar to
    private func setToolBarForTextField(_ sender: UITextField) {
        // init toolbar for keyboard
        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 50))
        let customDoneButton = UIButton.init(frame: CGRect(x: 0, y: 0, width: toolbar.bounds.size.width, height: toolbar.bounds.size.height))
        customDoneButton.setTitle("Done", for: .normal)
        customDoneButton.setTitleColor(.white, for: .normal)
        customDoneButton.backgroundColor = UIColor().hexStringToUIColor(hex: "0065B1")
        customDoneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        let doneBtn = UIBarButtonItem(customView: customDoneButton)
        toolbar.setItems([doneBtn], animated: false)
        toolbar.sizeToFit()

        sender.inputAccessoryView = toolbar
        sender.layer.borderColor = (UIColor(red: 0/255, green: 159/255, blue: 228/255, alpha: 1)).cgColor
    }

    /// THIS FUNCTION IS ONLY FOR UI. It will end keyboard editing and is the action for the done button in the
    /// UITextfield toolbar.
    @objc private func doneButtonAction() {
        view.endEditing(true)
    }
}

extension TransactionOptionsViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return transactionOptionsArray.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 7 {
            return 80
        }
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 || indexPath.row == 9 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "OptionsCell") as? OptionsCell {
                cell.lblOp.text = transactionOptionsArray[indexPath.row]
                return cell
            }
        } else if indexPath.row == 8 {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TagsCell") as? TagsCell else {return UITableViewCell()}
            if let tag = transactionOptions.tag {
                if !tag.isEmpty {
                    cell.txtTags.text = transactionOptions.tag
                }
            }
            return cell
            
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionOptionsCell") as? TransactionOptionsCell else {return UITableViewCell()}
            cell.lblOption.text = transactionOptionsArray[indexPath.row]
            cell.switchOption.tag = indexPath.row
            cell.switchOption.addTarget(self, action: #selector(switchHandler(_:)), for: .valueChanged)
            if indexPath.row > 9 {
                updateSwitchesForm(transactionCell: cell, indexPath: indexPath)
            } else {
                updateSwitches(transactionCell: cell, indexPath: indexPath)
            }
            return cell
        }
        return UITableViewCell()
    }
    
    func updateSwitches(transactionCell: TransactionOptionsCell, indexPath: IndexPath) {
        switch indexPath.row {
        case 1:
            transactionCell.switchOption.isOn = transactionOptions.isAuthCapture
        case 2:
            transactionCell.switchOption.isOn = transactionOptions.showPromptInApp
        case 3:
            transactionCell.switchOption.isOn = transactionOptions.showPromptInCardReader
        case 4:
            transactionCell.switchOption.isOn = transactionOptions.tippingOnReaderEnabled
        case 5:
            transactionCell.switchOption.isOn = transactionOptions.amountBasedTipping
        case 6:
            transactionCell.switchOption.isOn = transactionOptions.quickChipEnabled
        case 7:
            transactionCell.switchOption.isOn = transactionOptions.qrcPromptEnabled
        default:
            print("Nothing")
        }
    }
    
    func updateSwitchesForm(transactionCell: TransactionOptionsCell, indexPath: IndexPath) {
        if let formFactorArray = transactionOptions.preferredFormFactors {
            for factor in formFactorArray {
                var tag: Int?
                switch factor {
                case PPRetailFormFactor.magneticCardSwipe:
                    tag = 10
                case PPRetailFormFactor.chip:
                    tag = 11
                case PPRetailFormFactor.emvCertifiedContactless:
                    tag = 12
                case PPRetailFormFactor.secureManualEntry:
                    tag = 13
                case PPRetailFormFactor.manualCardEntry:
                    tag = 14
                default:
                    print("Nothing")
                }
                if let tag = tag {
                    if transactionCell.switchOption.tag == tag {
                        transactionCell.switchOption.isOn = true
                    }
                }
                
            }
            
        }
    }
}

extension TransactionOptionsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let merchantStoreId = textField.text {
            if merchantStoreId.count > 1 {
                UserDefaults.standard.set(merchantStoreId, forKey: "merchantStoreId")
                let merchant = PPRetailMerchant()
                merchant?.storeId = merchantStoreId
            }
        }
        return true
    }
    
}
