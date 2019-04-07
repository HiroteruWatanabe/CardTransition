//
//  UIViewControllerCardTransition.swift
//  CardTransition
//
//  Created by Hiroteru Watanabe on 2019/04/07.
//

import UIKit

public protocol UIViewControllerCardTransition {
    
    var previewingViewController: UIViewController! { get set }
    var previewingViewHeight: CGFloat { get }
    var statusBarStyle: UIStatusBarStyle { get set }
    
    func didStartTransitionTo(state: CardTransitionTabBarController.CardState, fractionComplete: CGFloat, animationDuration: TimeInterval)
    func didEndTransitionTo(state: CardTransitionTabBarController.CardState, fractionComplete: CGFloat, animationThreshold: CGFloat)
    func updateTransition(fractionComplete: CGFloat)
    func continueTransition(fractionComplete: CGFloat, animationThreshold: CGFloat)
}


