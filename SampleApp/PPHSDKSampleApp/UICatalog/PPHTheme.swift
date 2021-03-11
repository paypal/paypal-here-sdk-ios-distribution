//
//  PPHTheme.swift
//  PPHSDKSampleApp
//
//  Created by Pranav Bhandari on 2/23/21.
//  Copyright © 2021 cowright. All rights reserved.
//

import UIKit

enum PPHTheme {

  /// PayPalSansBig-Light font, 17 pt font size
  case sansBigLight

  /// PayPalSansBig-Regular font, 17 pt font size
  case sansBigRegular

  var fontColor: UIColor {
    switch self {
    case .sansBigLight:
      return PPHColor.black

    case .sansBigRegular:
      return PPHColor.black
    }

  }

  var fontSize: CGFloat {
    switch self {
    case .sansBigLight, .sansBigRegular:
      return 17.0
    }
  }

  var fontFamily: String {
    switch self {
    case .sansBigLight:
      return "PayPalSansBig-Light"

    case .sansBigRegular:
      return "PayPalSansBig-Regular"
    }
  }
}
