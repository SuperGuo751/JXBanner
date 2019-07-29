//
//  JXBanner.swift
//  JXBanner_Example
//
//  Created by 谭家祥 on 2019/6/6.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import JXPageControl

// MARK: - JXBannerType
public class JXBanner: JXBaseBanner, JXBannerType {

    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupBase()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupBase()
    }
    
    private func setupBase() {
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    public var dataSource: JXBannerDataSource? { didSet { reloadView() }}
    
    public var delegate: JXBannerDelegate?
    
    /// Outside of pageControl
    var pageControl: (UIView & JXPageControlType)?
    
    override func setCurrentIndex() {
        let point = CGPoint(x: collectionView.contentOffset.x + collectionView.frame.width * 0.5,
                            y: collectionView.contentOffset.y + collectionView.frame.height * 0.5)
        if let indexPath = collectionView.indexPathForItem(at: point) {
            let currentPage = indexOfIndexPath(indexPath)
            pageControl?.currentPage = currentPage
            delegate?.jxBanner(self, center: currentPage)
        }
    }

    /// The refresh UI, get data from
    public func reloadView() {
        
        // Stop Animation
        stop()
        
        // refresh
        refreshDataSource()
        refreshDelegate()
        refreshData()
        
        // Start Animation
        start()
    }

}

// MARK: - Private mothod
extension JXBanner {
    
    private func refreshDataSource() {
        
        // DataSource
        if let _ = dataSource?.jxBanner(numberOfItems: self),
            let tempDataSource = dataSource {
            
            // Register cell
            if let register = dataSource?.jxBanner(self) {
                collectionView.register(
                    register.type,
                    forCellWithReuseIdentifier: register.reuseIdentifier)
                cellRegister = register
            }
            
            // numberOfItems
            pageCount = tempDataSource.jxBanner(numberOfItems: self)
            
            // params
            params = dataSource?.jxBanner(self,
                                          params: params) ?? params
            
            // layoutParams
            layout.params = tempDataSource.jxBanner(self,
                                                    layoutParams: layout.params!)
            
            // PageControl
            refreshPageControl()
        }
    }
    
    
    private func refreshPageControl() {
        self.pageControl?.removeFromSuperview()
        self.pageControl = nil
        if params.isShowPageControl {
            let pBuilder = dataSource?.jxBanner(pageControl: self,
                                                numberOfPages: pageCount,
                                                coverView: coverView,
                                                builder: pageControlBuilder())
            if let tempPageControl = pBuilder?.pageControl{
                pageControl = tempPageControl
                pageControl?.numberOfPages = pageCount
                coverView.addSubview(tempPageControl)
            }
            if let layout = pBuilder?.layout {
                layout()
            }
        }
    }
    
    private func refreshDelegate() {
        // Dalegate
        if let tempDelegate = delegate {
            tempDelegate.jxBanner(self, coverView: coverView)
        }
    }
    
    private func refreshData() {
        
        // Reinitialize data
        params.currentRollingDirection = .right
        collectionView.setCollectionViewLayout(layout, animated: true)
        collectionView.bounces = params.isBounces
        collectionView.reloadData()
        if pageCount == 1,
            params.cycleWay == .forward {
            params.cycleWay = .skipEnd
        }
        placeholderImgView.backgroundColor = UIColor.red
        reinitializeIndexPath()
    }
    
    /// Reload current indexpath
    private func reinitializeIndexPath() {
        if pageCount > 0,
            params.cycleWay == .forward {
            // Take the middle group and show it
            currentIndexPath = IndexPath(row: (kMultiplier * pageCount / 2),
                                         section: 0)
        }else {
            currentIndexPath = IndexPath(row: 0, section: 0)
        }
        if pageCount > 0 {
            scrollToIndexPath(currentIndexPath, animated: false)
        }
    }
    
    @objc internal override func autoScroll() {
        guard pageCount > 1 else { return }
        
        // 判断是否在屏幕中
        guard self.window != nil else { return }
        let rectInWindow = convert(frame, to: UIApplication.shared.keyWindow)
        guard (UIApplication.shared.keyWindow?.bounds.intersects(rectInWindow) ?? false)
            else { return }
        
        
        switch params.cycleWay {
            
        case .forward:
            
            currentIndexPath = currentIndexPath + 1
            scrollToIndexPath(currentIndexPath,
                              animated: true)
        case .skipEnd:
            
            if currentIndexPath.row == pageCount - 1 {
                currentIndexPath = IndexPath(row: 0, section: 0)
                
                scrollToIndexPath(currentIndexPath, animated: false)
                scrollViewDidEndScrollingAnimation(collectionView)
                if let transitionType = params.edgeTransitionType?.rawValue {
                    let transition = CATransition()
                    transition.duration = CFTimeInterval(0.3)
                    transition.subtype = params.edgeTransitionSubtype
                    transition.type = CATransitionType(rawValue: transitionType)
                    transition.isRemovedOnCompletion = true
                    collectionView.layer.add(transition, forKey: nil)
                }
                
            } else {
                currentIndexPath = currentIndexPath + 1
                scrollToIndexPath(currentIndexPath, animated: true)
            }
        
        case .rollingBack:

            
            switch params.currentRollingDirection {
                
            case .right:
                
                if currentIndexPath.row == pageCount - 1 {
                    currentIndexPath = currentIndexPath - 1
                    params.currentRollingDirection = .left
                }else {
                    currentIndexPath = currentIndexPath + 1
                }
                scrollToIndexPath(currentIndexPath, animated: true)
                
            case .left:
                
                if currentIndexPath.row == 0 {
                    currentIndexPath = currentIndexPath + 1
                    params.currentRollingDirection = .right
                }else {
                    currentIndexPath = currentIndexPath - 1
                }
                scrollToIndexPath(currentIndexPath, animated: true)
            }
        }
    }
    
    /// cell错位检测和调整
    private func adjustErrorCell(isScroll: Bool)
    {
        let indexPaths = collectionView.indexPathsForVisibleItems
        var attriArr = [UICollectionViewLayoutAttributes?]()
        for indexPath in indexPaths {
            let attri = collectionView.layoutAttributesForItem(at: indexPath)
            attriArr.append(attri)
        }
        let centerX: CGFloat = collectionView.contentOffset.x + collectionView.frame.width * 0.5
        var minSpace = CGFloat(MAXFLOAT)
        var shouldSet = true
        if layout.params?.layoutType != nil && indexPaths.count <= 2 {
            shouldSet = false
        }
        for atr in attriArr {
            if let obj = atr, shouldSet {
                obj.zIndex = 0;
                if(abs(minSpace) > abs(obj.center.x - centerX)) {
                    minSpace = obj.center.x - centerX;
                    currentIndexPath = obj.indexPath;
                }
            }
        }
        if isScroll {
            scrollViewWillBeginDecelerating(collectionView)
        }
    }
}

// MARK: - UIScrollViewDelegate
extension JXBanner {
    
    /// Began to drag and drop
    public func scrollViewWillBeginDragging(
        _ scrollView: UIScrollView) { pause() }
    
    /// The drag is about to end
    public func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        
        pause()
        
        if params.cycleWay != .forward {
            if velocity.x >= 0 ,
                currentIndexPath.row == pageCount - 1 { return }
            if velocity.x <= 0 ,
                currentIndexPath.row == 0 { return }
        }
        
        // 这里不用考虑越界问题,其他地方做了保护
        if velocity.x > 0 {
            //左滑,下一张
            currentIndexPath = currentIndexPath + 1
        }else if velocity.x < 0 {
            //右滑, 上一张
            currentIndexPath = currentIndexPath - 1
        }else {
            print("未滑动, 不翻页")
            adjustErrorCell(isScroll: true)
        }
    }
    
    /// It's going to start slowing down
    public  func scrollViewWillBeginDecelerating(
        _ scrollView: UIScrollView) {
        scrollToIndexPath(currentIndexPath,
                          animated: true)
    }
    
    /// End to slow down
    public func scrollViewDidEndDecelerating(
        _ scrollView: UIScrollView) {}
    
    /// Scroll animation complete
    public func scrollViewDidEndScrollingAnimation(
        _ scrollView: UIScrollView) {
        start()
        setCurrentIndex()
    }
    
    /// Rolling in the
    public func scrollViewDidScroll(
        _ scrollView: UIScrollView) {
//        pause()
    }

}

// MARK:- UICollectionViewDataSource, UICollectionViewDelegate
extension JXBanner:
    UICollectionViewDataSource,
UICollectionViewDelegate {
    
    public func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int)
        -> Int {
            return params.cycleWay == .forward ? kMultiplier * pageCount : pageCount
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
        -> UICollectionViewCell {
            
            print(indexPath)
            
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: cellRegister.reuseIdentifier,
                for: indexPath)
            
            if let bannerViewCell = cell as? JXBannerBaseCell {
                return dataSource?.jxBanner(self,
                                            cellForItemAt: indexOfIndexPath(indexPath),
                                            cell: bannerViewCell) ?? bannerViewCell
            }
            
            return cell
    }
    
    
    public func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        delegate?.jxBanner(self,
                           didSelectItemAt: indexOfIndexPath(indexPath))
        adjustErrorCell(isScroll: true)
    }
    
    func indexOfIndexPath(_ indexPath : IndexPath)
        -> Int {
            return Int(indexPath.item % pageCount)
    }
}