//
//  RoundButton.swift
//  iOS-FilterCameraApp
//
//  Created by EugenKGD on 06/08/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//

import UIKit

class RoundAnimationButton: UIButton {
    
    enum Constants {
        static let animationDuration: CFTimeInterval = 0.3
        static let backgroundColor: UIColor = UIColor.gray
        static let defaultWidth: CGFloat = 60
        static let scaleAnimation: CGFloat = 1.5
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Constants.backgroundColor
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height/2
        layer.borderWidth = 2
        layer.borderColor = UIColor.gray.cgColor
    }
    
    func touchUpAnimation() {
        UIView.animate(withDuration: Constants.animationDuration) { [weak self] in
            self?.transform = .identity
        }
    }
    
    func touchDownAnimation() {
        UIView.animate(withDuration: Constants.animationDuration) { [weak self] in
            self?.transform = CGAffineTransform(scaleX: Constants.scaleAnimation,
                                                y: Constants.scaleAnimation)
        }
    }
}
