//
//  Array+Extension.swift
//  iOS-FilterCameraApp
//
//  Created by EugenKGD on 03/08/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//

import Foundation

extension Array where Element: Hashable {
    var maxIndex: Int {
        let currentCount = self.count
        return currentCount ==
            Int.zero ? Int.zero : currentCount - 1
    }
}
