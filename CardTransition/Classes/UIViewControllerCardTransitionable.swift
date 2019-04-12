//
//  UIViewControllerCardTransition.swift
//  CardTransition
//
//  Created by Hiroteru Watanabe on 2019/04/07.
//

import UIKit

public protocol UIViewControllerCardTransitionable {
    
    var previewingViewController: UIViewController? { get set }
    var previewingViewHeight: CGFloat { get }
    var statusBarStyle: UIStatusBarStyle { get set }
    var isExpanded: Bool { get set }
    
    func didStartTransitionTo(state: CardState, fractionComplete: CGFloat, animationDuration: TimeInterval)
    func didEndTransitionTo(state: CardState, fractionComplete: CGFloat, animationThreshold: CGFloat)
    func didUpdateTransition(fractionComplete: CGFloat)
    func continueTransition(fractionComplete: CGFloat, animationThreshold: CGFloat)
}


