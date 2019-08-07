//
//  AVCaptureSession+Extension.swift
//  iOS-FilterCameraApp
//
//  Created by EugenKGD on 04/08/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//

import AVFoundation

extension AVCaptureSession {
    
    func cleanAll() {
        self.stopRunning()
        self.inputs.forEach({ self.removeInput($0) })
        self.outputs.forEach({ self.removeOutput($0) })
    }
}
