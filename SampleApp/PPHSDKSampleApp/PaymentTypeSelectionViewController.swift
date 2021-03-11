//
//  PaymentTypeSelectionViewController.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/12/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit

// TODO: Replace with payment type models including array of available options
enum FeaturedPaymentType: String {
  case allOtherPayments = "All Other Payments"
  case vault = "Vault"
}

class PaymentTypeSelectionViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

  @IBOutlet weak var tableView: UITableView!

  var featuredPayments: [FeaturedPaymentType] = [.allOtherPayments, .vault]

  override func viewDidLoad() {
    super.viewDidLoad()

    setupTableView()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    clearSelectedTableViewCell()
    self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
  }

  // MARK: - Table View
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return featuredPayments.count
  }

  func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let cell = tableView.dequeueReusableCell(withIdentifier: PaymentTypeTableViewCell.cellIdentifier) as? PaymentTypeTableViewCell else {
      return UITableViewCell()
    }

    cell.typeLabel.text = featuredPayments[indexPath.row].rawValue

    return cell
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch featuredPayments[indexPath.row] {
    case .allOtherPayments:
      performSegue(withIdentifier: "goToPmtPage", sender: nil)
    default: // .vault
      performSegue(withIdentifier: "goToVault", sender: nil)
    }
  }

  fileprivate func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.rowHeight = view.frame.height / 10
  }

  fileprivate func clearSelectedTableViewCell() {
    if let selectedPath = tableView.indexPathForSelectedRow {
      tableView.deselectRow(at: selectedPath, animated: true)
    }
  }

  // MARK: - Navigation

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

    // TODO: Pass payment type model to configure vc
    if segue.identifier == "goToVaultPmtPage" {
      if let destinationVC = segue.destination as? VaultPaymentViewController,
         let indexPath = tableView.indexPathForSelectedRow,
         let cell = tableView.cellForRow(at: indexPath) as? PaymentTypeTableViewCell {
        destinationVC.title = cell.typeLabel.text
      }
    }
  }

}
