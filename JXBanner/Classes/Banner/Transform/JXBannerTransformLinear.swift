//
//  JXBannerTransformLinear.swift
//  JXBanner_Example
//
//  Created by Code_JX on 2019/5/14.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

public struct JXBannerTransformLinear: JXBannerTransformable {
    
    public init() {}
    
    public func transformToAttributes(collectionView: UICollectionView,
                                       params: JXBannerLayoutParams,
                                       attributes: UICollectionViewLayoutAttributes) {
        
        let collectionViewWidth = collectionView.frame.width
        let collectionViewHeight = collectionView.frame.height
        if collectionViewWidth <= 0 || collectionViewHeight <= 0 { return }
        
        let centerX = collectionView.contentOffset.x + collectionViewWidth * 0.5
        let delta = abs(attributes.center.x - centerX)
        
        // 计算缩放比例和透明度
        let scale = max(1 - delta / collectionViewWidth * params.rateOfChange, params.minimumScale)
        let alpha = max(1 - delta / collectionViewWidth, params.minimumAlpha)
        
        // 创建缩放变换
        var transform = CGAffineTransform(scaleX: scale, y: scale)
        var _alpha = alpha
        
        // 计算翻译量
        let location = JXBannerTransfrom.itemLocation(viewCentetX: centerX, itemCenterX: attributes.center.x)
        let rate = 1.05 + params.rateHorisonMargin
        var translate: CGFloat = 0
        
        // 根据位置调整翻译量
        switch location {
        case .left:
            translate = rate * attributes.size.width * (1 - scale) / 2
        case .right:
            translate = -rate * attributes.size.width * (1 - scale) / 2
        case .center:
            _alpha = 1.0
        }
        
        // 计算底部对齐的偏移量
        let bottomOffset = (attributes.size.height * (1 - scale)) / 2
        transform = transform.translatedBy(x: translate, y: bottomOffset) // 向上平移以保持底部对齐
        
        // 设置变换和透明度
        attributes.transform = transform
        attributes.alpha = _alpha
    }
}




