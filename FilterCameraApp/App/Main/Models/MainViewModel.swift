//
//  MainViewModel.swift
//  iOS-FilterCameraApp
//
//  Created by EugenKGD on 03/08/2019.
//  Copyright © 2019 Eugene Lezov. All rights reserved.
//

import AVFoundation
import RxCocoa

protocol MainViewModelAbstract {
    var cameraTypeDynamic: BehaviorRelay<AVCaptureDevice.Position> { get set }
    var currentFilterType: MainViewModel.FilterType { get set }
}

class MainViewModel: MainViewModelAbstract {
    var cameraTypeDynamic = BehaviorRelay<AVCaptureDevice.Position>(value: .front)
    var currentFilterType: MainViewModel.FilterType = .withoutFilter
    
    enum FilterType: String, CaseIterable {
        case withoutFilter
        case gaussianBlur = "CIGaussianBlur"
        case comicEffect = "CIComicEffect"
        case crystallize = "CICrystallize"
        
        struct FilterComponent {
            struct FilterParameter {
                let key: String
                let value: Any
            }
            let name: String
            let parameters: [FilterParameter]?
        }
        
        var filterEnabled: Bool {
            return self != .withoutFilter
        }
        
        var filterComponent: FilterComponent? {
            switch self {
            case .withoutFilter:
                return nil
            case .gaussianBlur:
                return FilterComponent(name: self.rawValue,
                                       parameters: [FilterComponent.FilterParameter(key: kCIInputRadiusKey,
                                                                                    value: CGFloat(10))])
            case .comicEffect:
                return FilterComponent(name: self.rawValue,
                                       parameters: nil)
            case .crystallize:
                return FilterComponent(name: self.rawValue,
                                       parameters: [FilterComponent.FilterParameter(key: kCIInputRadiusKey,
                                                                                    value: CGFloat(20))])
            }
        }
        
        mutating func next() {
            let allCases = type(of: self).allCases
            self = allCases[(allCases.index(of: self)! + 1) % allCases.count]
        }
        
        mutating func previous() {
            let allCases = type(of: self).allCases
            let currentIndex = allCases.index(of: self)!
            let extendIndex = currentIndex - 1
            let index = extendIndex < 0 ? allCases.maxIndex : extendIndex
            self = allCases[index % allCases.count]
        }
    }
}
