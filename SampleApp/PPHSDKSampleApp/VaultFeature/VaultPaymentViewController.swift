//
//  VaultPaymentViewController.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/12/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit
import PayPalRetailSDK

class VaultPaymentViewController: UIViewController, PPHRetailSDKAppDelegate {

    // MARK: - Outlets
    @IBOutlet weak var amountView: UIView!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var customerIdTextField: UITextField!
    @IBOutlet weak var payButton: UIButton!
    @IBOutlet weak var vaultSwitch: UISwitch!
    @IBOutlet weak var vaultSwitchLabel: UILabel!

    // MARK: - Properties
    var vaultTrxModel = VaultTransactionModel() {
        didSet {
            updateWithVaultTransactionModel()
        }
    }

    // MARK: - View Life Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        PayPalRetailSDK.setRetailSDKAppDelegate(self)
        setupDefaultViews()
    }

    override func viewDidAppear(_ animated: Bool) {
        customerIdTextField.becomeFirstResponder()
    }

    // MARK: - Actions

    @IBAction func payButtonTapped(_ sender: UIButton) {

        // Begins payment sequence.
        vaultTrxModel.submitTransaction { (responseTrx) in
            self.vaultTrxModel = responseTrx
        }
    }

    @IBAction func vaultSwitchTapped(_ sender: UISwitch) {
        setVaultTypeOption()
        setPayButtonText()
        setAmountViewAppearance()
        setVaultSwitchLabelText()
    }

    @IBAction func optionsButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "goToOptionsVC", sender: nil)
    }

    // MARK: - Update From Model Method

    func updateWithVaultTransactionModel() {

        if let errMsg = vaultTrxModel.errorMsg {
            alertWith(title: errMsg.title, message: errMsg.message)
        } else if let segueueName = vaultTrxModel.segueTitle {
            self.performSegue(withIdentifier: segueueName, sender: nil)
        } else {
            // TODO: Do we expect other view related info to change?
        }
    }

    // MARK: - PPHRetailSDKAppDelegate Method

    func getCurrentNavigationController() -> UINavigationController! {
        return self.navigationController
    }

    // MARK: - Navigation Methods

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToVaultCompletedVC" {
            if let pmtCompletedViewController = segue.destination as? VaultPaymentCompletedViewController {
                pmtCompletedViewController.trxModel = vaultTrxModel
            }
        } else if segue.identifier == "goToOptionsVC" {
            if let transactionOptionsController = segue.destination as? TransactionOptionsViewController {
                transactionOptionsController.delegate = self
                transactionOptionsController.formFactorArray = self.vaultTrxModel.formFactorArray
                transactionOptionsController.transactionOptions = self.vaultTrxModel.options
            }
        }
    }

    // MARK: - Options Helper Method

    fileprivate func setVaultTypeOption() {
        self.vaultTrxModel.options?.vaultType = vaultSwitch.isOn ?  .payAndVault : .vaultOnly
    }

    // MARK: - UI Methods
    fileprivate func setupDefaultViews() {
        setupTextField()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }

    fileprivate func setAmountViewAppearance() {
        amountView.isHidden = !vaultSwitch.isOn
        amountView.isUserInteractionEnabled = vaultSwitch.isOn
    }

    fileprivate func setVaultSwitchLabelText() {
        vaultSwitchLabel.text = vaultSwitch.isOn ? "Vault & Pay" : "Vault Only"
    }

    fileprivate func alertWith(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default)
        alertController.addAction(okAction)
        self.present(alertController, animated: true)
    }

    func setPayButtonText() {
        let title = vaultSwitch.isOn ? "Pay & Vault" : "Vault Only"
        payButton.setTitle(title, for: .normal)
    }

    fileprivate func setupTextField() {
        amountTextField.text = ""
        customerIdTextField.text = ""
        amountTextField.placeholder = "\(vaultTrxModel.currencySymbol) 0.00"

        // init toolbar for keyboard
        let toolbar: UIToolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 30))
        // create left side empty space so that done button set on right side
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneBtn = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonAction))
        toolbar.setItems([flexSpace, doneBtn], animated: false)
        toolbar.sizeToFit()

        // setting toolbar as inputAccessoryView
        amountTextField.inputAccessoryView = toolbar
        customerIdTextField.inputAccessoryView = toolbar

        amountTextField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
        customerIdTextField.addTarget(self, action: #selector(editingChanged(_:)), for: .editingChanged)
    }

    // Function to handle real-time changes in the invoice/payment amount and customerId text fields. The
    @objc func editingChanged(_ textField: UITextField) {
        if textField == amountTextField {
            if let amountString = textField.text?.currencyInputFormatting() {
                textField.text = amountString
                vaultTrxModel.amountString = amountString
            }
        } else if textField == customerIdTextField {
            if let customerId = textField.text {
                vaultTrxModel.options?.vaultCustomerId = customerId
            }
        }
    }

    @objc func doneButtonAction() {
        self.view.endEditing(true)
    }
}

// MARK: - Transaction Options Controller Delegate Methods. *** Use this if we want the seperate options menu ***
extension VaultPaymentViewController: TransactionOptionsViewControllerDelegate {

    func transactionOptions(controller: TransactionOptionsViewController, options: PPRetailTransactionBeginOptions) {
        self.vaultTrxModel.options = options
    }

    func transactionOptionsFormFactors(controller: TransactionOptionsViewController, formFactors: [PPRetailFormFactor]!) {
        self.vaultTrxModel.formFactorArray = formFactors
    }
}
