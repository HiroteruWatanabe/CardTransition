//
//  CardViewController.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/05.
//  Copyright © 2019 HiroteruWatanabe. All rights reserved.
//

import UIKit
import CardTransition

class CardViewController: UIViewController & UIViewControllerCardTransition {
    
    var previewingViewController: UIViewController!
    
    var previewingViewHeight: CGFloat {
        return traitCollection.horizontalSizeClass == .regular ? 49 : 80
    }
    
    var statusBarStyle: UIStatusBarStyle = .default
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == "previewingView" {
            previewingViewController = segue.destination
        }
    }
    
}

