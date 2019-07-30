//
//  JXBannerDataSource.swift
//  JXBanner_Example
//
//  Created by Code_JX on 2019/6/1.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit

public protocol JXBannerDataSource {
    
    /// Register the bannerCell and reuseIdentifier
    func jxBanner(_ banner: JXBannerType)
        -> (JXBannerCellRegister)
    
    /// How many pages does banner View have?
    func jxBanner(numberOfItems banner: JXBannerType)
        -> Int
    
    /// Set the closure of the banner item information
    func jxBanner(_ banner: JXBannerType,
                  cellForItemAt index: Int,
                  cell: JXBannerBaseCell)
        -> JXBannerBaseCell
    
    /// Set the closure of the banner Params
    func jxBanner(_ banner: JXBannerType,
                  params: JXBannerParams)
        -> JXBannerParams
    
    /// Set the closure of the banner layout Params
    func jxBanner(_ banner: JXBannerType,
                  layoutParams: JXBannerLayoutParams)
        -> JXBannerLayoutParams
    
    /// External pageControl replaces the default pageControl
    func jxBanner(pageControl banner: JXBannerType,
                  numberOfPages: Int,
                  coverView: UIView,
                  builder: pageControlBuilder) -> pageControlBuilder
}

/// The default implementation
extension JXBannerDataSource {
    
    /// Set the closure of the banner Params
    public func jxBanner(_ banner: JXBannerType,
                         params: JXBannerParams)
        -> JXBannerParams {
        return params
    }
    
    /// Set the closure of the banner layout Params
    public func jxBanner(_ banner: JXBannerType,
                             layoutParams: JXBannerLayoutParams)
        -> JXBannerLayoutParams {
        return layoutParams
    }

    /// External pageControl replaces the default pageControl
    func jxBanner(pageControl banner: JXBannerType,
                  numberOfPages: Int,
                  coverView: UIView,
                  builder: pageControlBuilder) -> pageControlBuilder {
        let pageControl = JXBannerDefaultPageControl()
        pageControl.frame = CGRect(x: 0,
                                   y: coverView.bounds.height - 24,
                                   width: coverView.bounds.width,
                                   height: 24)
        pageControl.autoresizingMask = [
            .flexibleWidth,
            .flexibleTopMargin
        ]
        builder.pageControl = pageControl
        
        return builder
    }
    
}