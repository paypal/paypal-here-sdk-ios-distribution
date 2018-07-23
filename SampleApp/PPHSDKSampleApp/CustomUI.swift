//
//  CustomUI.swift
//  PPHSDKSampleApp
//
//  Created by Wright, Cory on 3/14/17.
//  Copyright © 2017 cowright. All rights reserved.
//

import UIKit

@IBDesignable
class RoundLabel: UILabel {
    
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

@IBDesignable
class CustomButton: UIButton {

    @IBInspectable var borderWidth: CGFloat = 1.0 {
        didSet{
            super.layoutIfNeeded()
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.white {
        didSet {
            super.layoutIfNeeded()
            layer.borderColor = borderColor.cgColor
        }
    }
    
    @IBInspectable var cornerRadius: CGFloat = 0 {
        didSet{
            super.layoutIfNeeded()
            layer.cornerRadius = cornerRadius
            layer.masksToBounds = cornerRadius > 0
        }
    }
    
    func changeToButtonWasSelected(_ button: CustomButton){
        button.borderWidth = 0.0
        button.backgroundColor = .clear
        button.cornerRadius = 0.0
        button.imageEdgeInsets.left = button.frame.width - 30
        button.setTitle("", for: .disabled)
        button.setImage(#imageLiteral(resourceName: "Check"), for: .disabled)
    }
    
    func changeButtonTitle(offline: Bool, forButton button: CustomButton){
        if offline {
            button.setTitle("ENABLED", for: .normal)
            button.titleEdgeInsets.left = 30
            button.setTitleColor(.green, for: .normal)
            button.imageView?.image = #imageLiteral(resourceName: "Arrow Right")
            button.imageEdgeInsets.left = button.frame.width - 10
        } else {
            button.setTitle("", for: .normal)
            button.titleEdgeInsets.left = 30
            button.setTitleColor(.red, for: .normal)
            button.imageView?.image = #imageLiteral(resourceName: "Arrow Right")
            button.imageEdgeInsets.left = button.frame.width - 10
        }
    }
}


