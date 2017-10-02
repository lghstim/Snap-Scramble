//
//  UIViewController+SwipeNavigationController.swift
//  SwipeNavigationController
//
//  Created by Kok Chung Law on 4/7/16.
//  Copyright © 2016 Lomotif Private Limited. All rights reserved.
//

import UIKit

public extension UIViewController {
    
    @objc public var containerSwipeNavigationController: SwipeNavigationController? {
        get {
            var parentViewController = self.parent
            while (parentViewController != nil) {
                if let swipeNavigationController = parentViewController as? SwipeNavigationController {
                    return swipeNavigationController
                }
                parentViewController = parentViewController?.parent
            }
            return nil
        }
    }
    
    @objc public func showLeftVC(swipeVC: SwipeNavigationController) {
        swipeVC.showEmbeddedView(position: .left)
    }
    
    @objc public func showCenterVC(swipeVC: SwipeNavigationController) {
        swipeVC.showEmbeddedView(position: .center)
    }
    
    @objc public func showBottomVC(swipeVC: SwipeNavigationController) {
        swipeVC.showEmbeddedView(position: .bottom)
    }
    
    @objc public func showTopVC(swipeVC: SwipeNavigationController) {
        swipeVC.showEmbeddedView(position: .top)
    }
    
    
    
    
}

