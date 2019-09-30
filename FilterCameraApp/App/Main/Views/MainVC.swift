//
//  ViewController.swift
//  Vision
//
//  Created by Eugene Lezov on 01/02/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//


import UIKit
import AVFoundation
import RxCocoa
import SnapKit

class MainVC: BaseVC {

    var captureCameraManager = CaptureCameraManager()
    var viewModel: MainViewModelAbstract = MainViewModel()
    
    fileprivate var previewView: UIImageView = {
        let preview = UIImageView()
        preview.isUserInteractionEnabled = true
        preview.contentMode = .scaleAspectFill
        return preview
    }()
    
    fileprivate var changeCameraButton: UIButton = {
        let button = UIButton()
        button.setBackgroundImage(UIImage(named: "changeCamera"), for: .normal)
        return button
    }()
    
    fileprivate var takePhotoButton: RoundAnimationButton = {
        let button = RoundAnimationButton()
        button.backgroundColor = UIColor.lightGray
        return button
    }()
    
    fileprivate var previewButton: UIButton = {
        let button = UIButton()
        button.imageView?.contentMode = .scaleAspectFill
        return button
    }()
    
    @objc func savePhoto() {
        captureCameraManager.savePhoto()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureSubscribes()
    }
}

fileprivate extension MainVC {
    func configureSwipeGesture() {
        func addSwipe(to swipeView: UIView,
                      direction: UISwipeGestureRecognizer.Direction) {
            let swipeGesture = UISwipeGestureRecognizer()
            swipeGesture.direction = direction
            swipeGesture
                .rx.event
                .bind(onNext: { self.didSwipe(sender: $0) })
                .disposed(by: self.disposeBag)
            swipeView.addGestureRecognizer(swipeGesture)
        }
    
        addSwipe(to: previewView, direction: .right)
        addSwipe(to: previewView, direction: .left)
    }
    
    @objc func didSwipe(sender: UISwipeGestureRecognizer) {
        switch sender.direction {
        case .left:
            viewModel.currentFilterType.next()
            captureCameraManager.currentFilter = viewModel.currentFilterType
        case .right:
            viewModel.currentFilterType.previous()
            captureCameraManager.currentFilter = viewModel.currentFilterType
        default:
            break
        }
    }
}

fileprivate extension MainVC {
    
    func configureSubscribes() {
        viewModel.cameraTypeDynamic
            .bind(onNext: { [weak self] cameraType in
                guard let self = self else { return }
                let currentBackgroundImage = self.changeCameraButton.backgroundImage(for: .normal)
                self.changeCameraButton.setBackgroundImage(currentBackgroundImage?.withHorizontallyFlippedOrientation(),
                                                           for: .normal)
                self.captureCameraManager.currentPosition = cameraType
        }).disposed(by: disposeBag)
        
        captureManagerSubscribes()
    }
    
    func configureUI() {
        func configureMainView() {
            view.addSubview(previewView)
            previewView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        func configureChangeCameraButton() {
            view.addSubview(changeCameraButton)
            changeCameraButton.snp.makeConstraints { make in
                make.height.width.equalTo(45)
                make.right.equalToSuperview().offset(-16)
                make.top.equalTo(self.view.snp.top).inset(32)
            }
            changeCameraButton.rx
                .tap
                .bind(onNext: { [weak self] _ in
                    guard let self = self else { return }
                    let nextCameraType: AVCaptureDevice.Position =
                        self.viewModel.cameraTypeDynamic.value == .front ?
                            .back : .front
                     self.viewModel.cameraTypeDynamic.accept(nextCameraType)
                })
                .disposed(by: disposeBag)
        }
        
        func configureTakeButton() {
            view.addSubview(takePhotoButton)
            takePhotoButton.snp.makeConstraints { make in
                make.height.width.equalTo(60)
                make.centerX.equalTo(self.view.snp.centerX)
                make.bottom.equalTo(self.view.snp.bottom).inset(32)
            }
            takePhotoButton.rx
                .tap
                .bind { self.savePhoto() }
                .disposed(by: disposeBag)
            
            takePhotoButton.rx
                .controlEvent([.touchUpInside, .touchUpOutside])
                .bind(onNext: { [weak takePhotoButton] _ in
                    takePhotoButton?.touchUpAnimation()
                })
                .disposed(by: disposeBag)
            
            takePhotoButton.rx
                .controlEvent([.touchDown])
                .bind(onNext: { [weak takePhotoButton] _ in
                    takePhotoButton?.touchDownAnimation()
                })
                .disposed(by: disposeBag)
        }
        
        func configurePreviewButton() {
            view.addSubview(previewButton)
            previewButton.snp.makeConstraints{
                $0.height.equalTo(100);
                $0.width.equalTo(75);
                $0.bottom.equalToSuperview().offset(-16)
                $0.leading.equalToSuperview().offset(16)
            }
            
            previewButton.rx
                .tap
                .subscribe({ _ in
                    self.showGallery(with: self.previewButton.image(for: .normal))
            
                })
            .disposed(by: disposeBag)
        }
        
        configureMainView()
        configureSwipeGesture()
        configureChangeCameraButton()
        configureTakeButton()
        configurePreviewButton()
    }
    
    func captureManagerSubscribes() {
        captureCameraManager.onSaveImage = { [weak self] cgImage in
            self?.saveUIImageToAlbum(cgImage: cgImage)
        }
        
        captureCameraManager
            .dynamicPreview
            .subscribe { [weak self] cgImage in
            guard
                let eventImage = cgImage.element,
                let previewImage = eventImage
            else { return }
            DispatchQueue.main.async { [weak self] in
                let image = UIImage(cgImage: previewImage)
                self?.previewView.image = image
            }
        }.disposed(by: disposeBag)
    }
}

fileprivate extension MainVC {
    
    func showGallery(with image: UIImage?) {
        guard let image = image else { return }
        let vc = UIStoryboard.getController(GalleryVC.self)
        vc.setup(image: image)
        self.present(vc,
                     animated: true,
                     completion: nil)
    }
    
    func saveUIImageToAlbum(cgImage: CGImage) {
        
        let orientation: UIImage.Orientation =
            viewModel.cameraTypeDynamic.value == AVCaptureDevice.Position.front ?
                UIImage.Orientation.leftMirrored:
                UIImage.Orientation.right
        let image = UIImage(cgImage: cgImage,
                            scale: 1.0,
                            orientation: orientation)
        
        previewButton.setImage(image,
                               for: .normal)
        
    }
}
