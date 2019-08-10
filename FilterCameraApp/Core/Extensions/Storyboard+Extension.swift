//
//  Storyboard+Extension.swift
//  iOS-FilterCameraApp
//
//  Created by EugenKGD on 10/08/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//

import UIKit



extension UIStoryboard {
    
    static func getController<T: UIViewController>(_: T.Type) -> T {
        let name = String(describing: T.self)
        let storyboard = UIStoryboard(name: name, bundle: nil)
        return storyboard.instantiateViewController(T.self, name: name)
    }
    
    func instantiateViewController<T: UIViewController>(_: T.Type, name: String) -> T {
        guard let vc = self.instantiateViewController(withIdentifier: name) as? T else {
            fatalError("View controller с идентификатором \(name) не найден")
        }
        return vc
    }
}
