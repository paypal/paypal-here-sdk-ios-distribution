//
//  StringExt.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 1/9/18.
//  Copyright © 2018 cowright. All rights reserved.
//

import UIKit


extension String {
    
    // Formatting for invoice amount text field
    func currencyInputFormatting() -> String {
        
        var number: NSDecimalNumber!
        let formatter = NumberFormatter()
        formatter.numberStyle = .currencyAccounting
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        
        var amountWithPrefix = self
        
        let regex = try! NSRegularExpression(pattern: "[^0-9]", options: .caseInsensitive)
        amountWithPrefix = regex.stringByReplacingMatches(in: amountWithPrefix, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSMakeRange(0, self.characters.count), withTemplate: "")
        
        let double = (amountWithPrefix as NSString).doubleValue
        number = NSDecimalNumber(value: (double / 100))
        
        guard number != 0 as NSDecimalNumber else {
            return ""
        }
        
        return formatter.string(from: number)!
    }
}
