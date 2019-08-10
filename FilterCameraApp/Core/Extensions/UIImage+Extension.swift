//
//  UIImage+Extension.swift
//  iOS-FilterCameraApp
//
//  Created by EugenKGD on 10/08/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//

import UIKit

extension UIImage {
    func imageWithColor(color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        color.setFill()
        guard
            let context = UIGraphicsGetCurrentContext(),
            let cgImage = self.cgImage else {
                
                return self
        }
        context.translateBy(x: 0, y: size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.setBlendMode(.normal)
        let rect = CGRect(origin: .zero, size: size)
        
        context.clip(to: rect, mask: cgImage)
        context.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() ?? self
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
