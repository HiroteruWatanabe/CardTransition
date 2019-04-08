//
//  SampleCardViewController2.swift
//  CardTransition_Example
//
//  Created by HiroteruWatanabe on 2019/04/08.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import CardTransition

class SampleCardViewController2: CardViewController {
    
    var previewingViewController: UIViewController?
    
    var previewingViewHeight: CGFloat = 64
    
    var statusBarStyle: UIStatusBarStyle = .default
    
    func didStartTransitionTo(state: CardState, fractionComplete: CGFloat, animationDuration: TimeInterval) {
        
    }
    
    func didEndTransitionTo(state: CardState, fractionComplete: CGFloat, animationThreshold: CGFloat) {
        
    }
    
    func didUpdateTransition(fractionComplete: CGFloat) {
        
    }
    
    func continueTransition(fractionComplete: CGFloat, animationThreshold: CGFloat) {
        
    }
    
    @IBAction func touchedUpInsideButton(_ sender: UIButton) {
        guard let cardTransitionViewController = parent as? CardTransitionViewController else { return }
        cardTransitionViewController.removeCardViewController(animated: true)
    }
    
}
