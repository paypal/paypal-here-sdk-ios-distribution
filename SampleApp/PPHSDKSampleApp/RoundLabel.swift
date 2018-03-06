//
//  RoundLabel.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 3/14/17.
//  Copyright © 2017 cowright. All rights reserved.
//

import UIKit

@IBDesignable public class RoundLabel: UILabel {
    
    @IBInspectable var borderColor: UIColor = UIColor.white {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 2.0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = 0.5 * bounds.size.width
        clipsToBounds = true
    }
}
