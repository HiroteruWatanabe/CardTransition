//
//  CardViewController.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/05.
//  Copyright © 2019 HiroteruWatanabe. All rights reserved.
//

import UIKit
import CardTransition

class SampleCardViewController: UIViewController {
    
    var isExpanded: Bool = false
    var previewingViewController: UIViewController?
    var sampleViewCollapsedConstraintGroup = LayoutConstraintGroup()
    var sampleViewExpandedConstraintGroup = LayoutConstraintGroup()
    var animator: UIViewPropertyAnimator?
    
    var previewingViewHeight: CGFloat {
        return traitCollection.horizontalSizeClass == .regular ? 49 : 80
    }
    
    var statusBarStyle: UIStatusBarStyle = .default
    
    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let sampleView = UIView()
        sampleView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sampleView)
        sampleView.backgroundColor = .red
        let collapsedTopConstraint = sampleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 8)
        sampleViewCollapsedConstraintGroup.append(collapsedTopConstraint)
        let collapsedLeadingConstraint = sampleView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8)
        sampleViewCollapsedConstraintGroup.append(collapsedLeadingConstraint)
        let collapsedWidthConstraint = sampleView.widthAnchor.constraint(equalToConstant: 44)
        sampleViewCollapsedConstraintGroup.append(collapsedWidthConstraint)
        sampleView.heightAnchor.constraint(equalTo: sampleView.widthAnchor, multiplier: 1.0).isActive = true
        
        sampleViewCollapsedConstraintGroup.isActive = true
        
        let expandedWidthConstraint = sampleView.widthAnchor.constraint(equalToConstant: 240)
        sampleViewExpandedConstraintGroup.append(expandedWidthConstraint)
        let expandedCenterXConstraint = sampleView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        sampleViewExpandedConstraintGroup.append(expandedCenterXConstraint)
        let expandedTopConstraint = sampleView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100)
        sampleViewExpandedConstraintGroup.append(expandedTopConstraint)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let identifier = segue.identifier else { return }
        if identifier == "previewingView" {
            previewingViewController = segue.destination
        }
    }
    
    @IBAction func touchedUpInsideButton(_ sender: UIButton) {
        guard let tabBarController = tabBarController as? CardTransitionTabBarController else { return }
        tabBarController.removeCardViewController(animated: true)
    }
    
    @IBAction func touchedUpInsideButton2(_ sender: UIButton) {
        guard let tabBarController = tabBarController as? SampleCardTransitionTabBarController else { return }
        if let _ = tabBarController.bannerView {
            tabBarController.removeBannerView()
        } else {
            tabBarController.setupBannerView()
        }
    }
}

extension SampleCardViewController: UIViewControllerCardTransitionable {
    func didStartTransitionTo(state: CardState, fractionComplete: CGFloat, animationDuration: TimeInterval) {
        self.animator?.stopAnimation(true)
        let animator = UIViewPropertyAnimator(duration: animationDuration, dampingRatio: 1) {
            switch state {
            case .collapsed:
                self.sampleViewExpandedConstraintGroup.isActive = false
                self.sampleViewCollapsedConstraintGroup.isActive = true
                
            case .expanded:
                self.sampleViewCollapsedConstraintGroup.isActive = false
                self.sampleViewExpandedConstraintGroup.isActive = true
            }
            
            self.view.layoutIfNeeded()
        }
        animator.startAnimation()
        self.animator = animator
    }
    
    func didEndTransitionTo(state: CardState, fractionComplete: CGFloat, animationThreshold: CGFloat) {
        animator?.fractionComplete = fractionComplete
        animator?.isReversed = fractionComplete <= animationThreshold
        animator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
    
    func didUpdateTransition(fractionComplete: CGFloat) {
        animator?.pauseAnimation()
        animator?.fractionComplete = fractionComplete
    }
    
    func continueTransition(fractionComplete: CGFloat, animationThreshold: CGFloat) {
        animator?.isReversed = fractionComplete <= animationThreshold
        animator?.continueAnimation(withTimingParameters: nil, durationFactor: 0)
    }
    
}
