//
//  PaymentTypeTableViewCell.swift
//  PPHSDKSampleApp
//
//  Created by Rosello, Ryan(AWF) on 2/11/19.
//  Copyright © 2019 cowright. All rights reserved.
//

import UIKit

class PaymentTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var typeLabel: UILabel!

    static let cellIdentifier = "PaymentTypeCell"

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
