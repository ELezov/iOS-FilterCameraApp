import UIKit
import Photos

final class GalleryVC: BaseVC {

    lazy var backgroundView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFill
        return imgView
    }()
    
    lazy var saveButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "Save")?.imageWithColor(color: UIColor.lightGray)
        button.setImage(image, for: .normal)
        return button
    }()
    
    lazy var closeButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "Close")?.imageWithColor(color: UIColor.lightGray)
        button.setBackgroundImage(image, for: .normal)
        return button
    }()
    
    lazy var toastLabel: UILabel = {
        let label = UILabel()
        label.alpha = 0
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 28)
        return label
    }()
    
    fileprivate var imageForSave: UIImage? {
        didSet {
            backgroundView.image = imageForSave
        }
    }
    
    func setup(image: UIImage) {
        self.imageForSave = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
}

fileprivate extension GalleryVC {
    
    func configureUI() {
        view.addSubview(backgroundView)
        backgroundView.snp.makeConstraints({ $0.edges.equalToSuperview() })
        
        view.addSubview(saveButton)
        saveButton.snp.makeConstraints({
            $0.width.height.equalTo(60)
            $0.bottom.equalTo(self.view.snp.bottom).inset(32)
            $0.centerX.equalTo(self.view.snp.centerX)
        })
        
        saveButton.rx
            .tap
            .subscribe(onNext: { self.savePhotoToLibrary() })
        .disposed(by: disposeBag)
        
        view.addSubview(closeButton)
        closeButton.snp.makeConstraints({
            $0.width.height.equalTo(45)
            $0.top.equalTo(self.view.snp.top).inset(16)
            $0.leading.equalTo(16)
        })
        closeButton.rx
            .tap
            .subscribe(onNext: { self.dismiss(animated: true, completion: nil)})
        .disposed(by: disposeBag)
        
        view.addSubview(toastLabel)
        toastLabel.snp.makeConstraints({
            $0.top.equalTo(self.view.snp.top).inset(48)
            $0.leading.trailing.equalTo(16)
        })
    }
    
    func savePhotoToLibrary() {
        guard let image = imageForSave else { return }
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAsset(from: image)
                }, completionHandler: { (isSuccess, _) in
                    guard isSuccess else { return }
                    DispatchQueue.main.async {
                        self?.showToast(text: "Photo is saved")
                    }
                })
            default:
                self?.showAlertNeedPermission()
            }
        }
    }
    
    func showAlertNeedPermission() {
        
        enum AlertConstants {
            static let title = "Error"
            static let message = "Please give access to photo library in settings"
            
            static let ok = "Ok"
            static let goToSetting = "Go to settings"
        }
        
        let alertController = UIAlertController(title: AlertConstants.title,
                                                message: AlertConstants.message,
                                                preferredStyle: UIAlertController.Style.alert)
        alertController.addAction(UIAlertAction(title: AlertConstants.ok,
                                                style: UIAlertAction.Style.default,
                                                handler: nil))
        alertController.addAction(UIAlertAction(title: AlertConstants.goToSetting,
                                                style: UIAlertAction.Style.default,
                                                handler: { _ in
                                                    guard
                                                        let settingsUrl = URL(string: UIApplication.openSettingsURLString)
                                                        else { return }
                                                    
                                                    if UIApplication.shared.canOpenURL(settingsUrl) {
                                                        UIApplication.shared.open(settingsUrl,
                                                                                  completionHandler: nil)
                                                    }
        }))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showToast(text: String) {
        toastLabel.text = text
        
        UIView.animate(withDuration: 0.5, animations: {
            self.toastLabel.alpha = 1.0
        })
        
        UIView.animate(withDuration: 0.5, delay: 1.0, options:
            .curveLinear, animations: {
                self.toastLabel.alpha = 0.0
        }, completion: nil)
    }
}
