//
//  ViewController.swift
//  Vision
//
//  Created by Eugene Lezov on 01/02/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//


import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    enum FilterType: String, CaseIterable {
        case comicEffect = "CIComicEffect"
        case bloom = "CIBloom"
        case boxBlur = "CIBoxBlur"
        case colorClump = "CIColorClamp"
        case colorPolynomial = "CIColorPolynomial"
        case colorInvert = "CIColorInvert"
        case falseColor = "CIFalseColor"
        case tonalEffect = "CIPhotoEffectTonal"
        case bumpDistorion = "CIBumpDistortion"
        
        static func random() -> FilterType {
            let all: [FilterType] = FilterType.allCases
            let randomIndex = Int(arc4random()) % all.count
            return all[randomIndex]
        }
        
        mutating func next() {
            let allCases = type(of: self).allCases
            self = allCases[(allCases.index(of: self)! + 1) % allCases.count]
        }
    }
    
    var captureSession = AVCaptureSession()
    var backCamera: AVCaptureDevice?
    var frontCamera: AVCaptureDevice?
    var currentCamera: AVCaptureDevice?
    
    var photoOutput: AVCapturePhotoOutput?
    var orientation: AVCaptureVideoOrientation = .portrait
    
    let context = CIContext()
    
    var currentFilterType: FilterType = .comicEffect
    
    var filterIsEnabled: Bool = true
    
    var lastOutputImage: UIImage?
    
    // MARK: - Outlets
    
    @IBOutlet weak var filteredImage: UIImageView!
    @IBOutlet weak var overlayView: UIView! {
        didSet {
            overlayView.backgroundColor = UIColor.clear
        }
    }
    @IBOutlet weak var buttonCheckOriginal: UIButton! {
        didSet {
            buttonCheckOriginal.setTitle("", for: .normal)
            buttonCheckOriginal.layer.cornerRadius = 22
            buttonCheckOriginal.backgroundColor = UIColor.white
            buttonCheckOriginal.addTarget(self,
                                          action: #selector(checkOriginal),
                                          for: .touchUpInside)
            buttonCheckOriginal.addTarget(self,
                                          action: #selector(checkOriginal),
                                          for: .touchDown)
        }
    }
    @IBOutlet weak var buttonSave: UIButton! {
        didSet {
            buttonSave.layer.cornerRadius = 28
            buttonSave.layer.borderColor = UIColor.white.cgColor
            buttonSave.layer.backgroundColor = UIColor.blue.cgColor
            buttonSave.addTarget(self,
                                 action: #selector(savePhoto),
                                 for: .touchUpInside)
        }
    }
    
    @objc func checkOriginal() {
        filterIsEnabled = !filterIsEnabled
    }
    
    @objc func savePhoto() {
        guard let selectedImage = lastOutputImage else {
            print("Image not found!")
            return
        }
        UIImageWriteToSavedPhotosAlbum(selectedImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
    }
    
    //MARK: - Add image to Library
    @objc func image(_ image: UIImage,
                     didFinishSavingWithError error: Error?,
                     contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            showAlertWith(title: "Save error", message: error.localizedDescription)
        } else {
            showAlertWith(title: "Saved!", message: "Your image has been saved to your photos.")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDevice()
        setupInputOutput()
        configureImageView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupInputOutputIfCan()
    }
    
    override func viewDidLayoutSubviews() {
        orientation = AVCaptureVideoOrientation(rawValue: UIApplication.shared.statusBarOrientation.rawValue)!
    }
    
    func configureImageView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(changeFilter))
        overlayView.addGestureRecognizer(tap)
    }
    
    @objc func changeFilter() {
        currentFilterType.next()
        print(currentFilterType.rawValue)
    }
}

fileprivate extension ViewController {
    
    func setupInputOutputIfCan() {
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.video) != .authorized
        {
            AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler:
                { (authorized) in
                    DispatchQueue.main.async
                        {
                            if authorized
                            {
                                self.setupInputOutput()
                            }
                    }
            })
        }
    }
    
    func setupDevice() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        
        for device in devices {
            if device.position == AVCaptureDevice.Position.back {
                backCamera = device
            }
            else if device.position == AVCaptureDevice.Position.front {
                frontCamera = device
            }
        }
        
        currentCamera = backCamera
    }
    
    func setupInputOutput() {
        do {
            setupCorrectFramerate(currentCamera: currentCamera!)
            let captureDeviceInput = try AVCaptureDeviceInput(device: currentCamera!)
            captureSession.sessionPreset = AVCaptureSession.Preset.hd1280x720
            if captureSession.canAddInput(captureDeviceInput) {
                captureSession.addInput(captureDeviceInput)
            }
            let videoOutput = AVCaptureVideoDataOutput()
            
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
            }
            captureSession.startRunning()
        } catch {
            print(error)
        }
    }
    
    func setupCorrectFramerate(currentCamera: AVCaptureDevice) {
        for vFormat in currentCamera.formats {
            //see available types
            //print("\(vFormat) \n")
            
            var ranges = vFormat.videoSupportedFrameRateRanges as [AVFrameRateRange]
            let frameRates = ranges[0]
            
            do {
                //set to 240fps - available types are: 30, 60, 120 and 240 and custom
                // lower framerates cause major stuttering
                if frameRates.maxFrameRate == 240 {
                    try currentCamera.lockForConfiguration()
                    currentCamera.activeFormat = vFormat as AVCaptureDevice.Format
                    //for custom framerate set min max activeVideoFrameDuration to whatever you like, e.g. 1 and 180
                    currentCamera.activeVideoMinFrameDuration = frameRates.minFrameDuration
                    currentCamera.activeVideoMaxFrameDuration = frameRates.maxFrameDuration
                }
            }
            catch {
                print("Could not set active format")
                print(error)
            }
        }
    }
    
    func showAlertWith(title: String, message: String){
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        connection.videoOrientation = orientation
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        guard let comicEffect = CIFilter(name: currentFilterType.rawValue) else { return }
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let cameraImage = CIImage(cvImageBuffer: pixelBuffer!)
        
        guard filterIsEnabled else {
            DispatchQueue.main.async {
                let filteredImage = UIImage(ciImage: cameraImage)
                self.filteredImage.image = filteredImage
            }
            return
        }
        
        comicEffect.setValue(cameraImage, forKey: kCIInputImageKey)
        
        guard
            let outputImage = comicEffect.outputImage,
            let cgImage = self.context.createCGImage(outputImage,
                                                     from: cameraImage.extent)
            else { return }
        
        DispatchQueue.main.async { [weak self] in
            let filteredImage = UIImage(cgImage: cgImage)
            self?.lastOutputImage = filteredImage
            self?.filteredImage.image = filteredImage
        }
    }
}
