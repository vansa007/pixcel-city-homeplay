//
//  BoundView.swift
//  pixcel-city-homeplay
//
//  Created by Vansa Pha on 10/12/17.
//  Copyright © 2017 Vansa Pha. All rights reserved.
//
import UIKit

@IBDesignable
class BoundView: UIView {
    @IBInspectable var viewRadius: CGFloat = 5.0 {
        didSet {
            self.layer.cornerRadius = viewRadius
        }
    }
    
    func setupView() {
        self.layer.cornerRadius = viewRadius
    }
    
    override func awakeFromNib() {
        setupView()
    }
    override func prepareForInterfaceBuilder() {
        setupView()
    }
}
