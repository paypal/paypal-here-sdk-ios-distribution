//
//  UILabel+Extensions.swift
//  PPHSDKSampleApp
//
//  Created by Pranav Bhandari on 2/23/21.
//  Copyright © 2021 cowright. All rights reserved.
//

import UIKit

extension UILabel {
  func applyTheme(theme: PPHTheme) {
    self.textColor = theme.fontColor
    self.font = UIFont(name: theme.fontFamily, size: theme.fontSize)
  }
}
