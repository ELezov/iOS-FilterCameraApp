//
//  CaptureCameraManager.swift
//  iOS-FilterCameraApp
//
//  Created by EugenKGD on 06/08/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//

import AVFoundation
import UIKit
import RxCocoa

protocol CaptureCameraManagerable {
    var dynamicPreview: BehaviorRelay<CGImage?> { get set }
    var currentPosition: AVCaptureDevice.Position { get set }
    var currentFilter: MainViewModel.FilterType { get set }
    
    typealias OnSaveImage = ((CGImage) -> Void)
    var onSaveImage: OnSaveImage? { get set }
}

class CaptureCameraManager: NSObject, CaptureCameraManagerable {
    
    enum Constants {
        static let sessionQueueLabel = "capture camera manager"
        static let previewBufferQueueLabel = "preview buffer queue"
        static let orientation: AVCaptureVideoOrientation = .portrait
    }
    
    var onSaveImage: OnSaveImage?
    
    var dynamicPreview = BehaviorRelay<CGImage?>(value: nil)
    
    fileprivate let captureSession = AVCaptureSession()
    fileprivate var currentCamera: AVCaptureDevice?
    fileprivate let sessionQueue = DispatchQueue(label: Constants.sessionQueueLabel)
    fileprivate let context = CIContext()
    
    
    
    fileprivate let previewQuality: AVCaptureSession.Preset = .medium
    
    var currentPosition: AVCaptureDevice.Position = .front {
        didSet {
            configurePermissions()
        }
    }
    
    
    var isHighResolutionPhotoEnabled: Bool = true
    var currentFilter: MainViewModel.FilterType = .withoutFilter
    
    // For capture photo
    lazy var photoOutput: AVCapturePhotoOutput = {
        let output = AVCapturePhotoOutput()
        if let photoOutputConnection = output.connection(with: AVMediaType.video) {
            photoOutputConnection.videoOrientation = Constants.orientation
        }
        output.isHighResolutionCaptureEnabled = true
        return output
    }()
    
    func configurePermissions() {
        
        func requestCameraPermission() {
            AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
                if granted {
                    self.setupCamera()
                }
            }
        }
        
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .notDetermined:
            requestCameraPermission()
        case .authorized:
            setupCamera()
        default:
            // TODO: Show Alert with route to Settings
            break
        }
    }
    
    func setupCamera() {
        configureCamera()
        configureCaptureSession()
    }
    
    func savePhoto() {
        let settings = AVCapturePhotoSettings()
        settings.isHighResolutionPhotoEnabled = isHighResolutionPhotoEnabled
        photoOutput.capturePhoto(with: settings,
                                 delegate: self)
    }
}

extension CaptureCameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        
        guard let cgImage = getImageFromBuffer(sampleBuffer: sampleBuffer,
                                               filterType: currentFilter) else { return }
        dynamicPreview.accept(cgImage)
    }
}

extension CaptureCameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        guard error == nil,
            let photoData = photo.fileDataRepresentation(),
            let photoOutputCI = CIImage(data: photoData)
        else { return }
        
        let outputCIImage = getImageWithFilter(by: currentFilter,
                                               inputImage: photoOutputCI)
        guard
            let outputCGImage = context.createCGImage(outputCIImage,
                                                      from: outputCIImage.extent)
            else { return }
        
        onSaveImage?(outputCGImage)
    }
}

fileprivate extension CaptureCameraManager {
    func configureCamera() {
        let deviceDiscoverySession =
            AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
                                             mediaType: AVMediaType.video,
                                             position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        currentCamera = devices.first(where: { $0.position == currentPosition })
    }
    
    func getImageFromBuffer(sampleBuffer: CMSampleBuffer,
                            filterType: MainViewModel.FilterType) -> CGImage? {
        guard
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return nil }
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer)
        let filteredImage = getImageWithFilter(by: filterType,
                                               inputImage: cameraImage)
        
        let cgImage = self.context.createCGImage(filteredImage,
                                                 from: cameraImage.extent)
        return cgImage
    }
    
    func getImageWithFilter(by filterType: MainViewModel.FilterType,
                            inputImage: CIImage) -> CIImage {
        guard filterType.filterEnabled,
            let filterComponent = filterType.filterComponent,
            let filter = CIFilter(name: filterComponent.name)
            else {
                return inputImage
        }
        filter.setValue(inputImage, forKey: kCIInputImageKey)
        
        for param in filterComponent.parameters ?? [] {
            if param.key == kCIInputRadiusKey,
                let radius = param.value as? CGFloat {
                let inputSizeFactor = min(inputImage.extent.width,
                                          inputImage.extent.height) / 1000
                let scaledRadius = radius * inputSizeFactor
                filter.setValue(scaledRadius, forKey: param.key)
            } else {
                filter.setValue(param.value, forKey: param.key)
            }
            
        }
        return filter.outputImage ?? inputImage
    }
    
    func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        guard
            let format = currentCamera.formats
                .first(where: { $0.videoSupportedFrameRateRanges.first?.maxFrameRate == 240})
            else { return }
        
        do {
            try currentCamera.lockForConfiguration()
            currentCamera.activeFormat = format
            currentCamera.activeVideoMinFrameDuration =
                format.videoSupportedFrameRateRanges.first?.minFrameDuration ?? CMTime()
            currentCamera.activeVideoMaxFrameDuration =
                format.videoSupportedFrameRateRanges.first?.maxFrameDuration ?? CMTime()
        } catch {
            print("Could not set active format")
            print(error)
        }
    }
    
    func configureCaptureSession() {
        do {
            guard let camera = currentCamera else { return }
            setupCorrectFramerate(currentCamera: camera)
            let captureDeviceInput = try AVCaptureDeviceInput(device: camera)
            captureSession.cleanAll()
            captureSession.sessionPreset = AVCaptureSession.Preset.photo
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
            }
            
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self,
                                                queue: DispatchQueue(label: Constants.previewBufferQueueLabel))
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            
            captureSession.startRunning()
            
            guard
                let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video),
                connection.isVideoOrientationSupported,
                connection.isVideoMirroringSupported
            else { return }
            connection.videoOrientation = Constants.orientation
            connection.isVideoMirrored = currentPosition == .front
        } catch {
            print("Cannot add output")
        }
    }
}
