//
//  SampleCardTransitionTabBarController.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/05.
//  Copyright © 2019 HiroteruWatanabe. All rights reserved.
//

import UIKit
import CardTransition

class SampleCardTransitionTabBarController: CardTransitionTabBarController {
    
    var bannerView: UIView?
    var bannerViewConstraints = LayoutConstraintGroup()
    var isHorizontalSizeClassRegular: Bool {
        return traitCollection.horizontalSizeClass == .regular
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cardViewCollapsedCornerRadius = 18
        if let cardViewController = UIStoryboard(name: "SampleCardViewController", bundle: nil).instantiateViewController(withIdentifier: "SampleCardViewController") as? SampleCardViewController {
            let _ = cardViewController.view
            setCardViewController(cardViewController)
        }
        hidesButterflyHandleWhenCollapsed = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupBannerView()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass {
            setupBannerView()
        }
    }
    
    override func setCardViewController(_ cardViewController: CardViewController) {
        super.setCardViewController(cardViewController)
        setupBannerView()
    }
    
    override func removeCardViewController(animated: Bool, completion: (() -> ())? = nil) {
        super.removeCardViewController(animated: animated) { [weak self] in
            self?.setupBannerView()
        }
    }
    
    func setupBannerView() {
        cardViewDestinationY = 55 + 44
        isCardViewShadowHidden = true
        let bannerView: UIView
        if let _bannerView = self.bannerView {
            bannerView = _bannerView
        } else {
            bannerView = UIView()
            self.bannerView = bannerView
            bannerView.backgroundColor = .orange
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(bannerView)
            bannerView.removeConstraints(bannerViewConstraints.constraints)
        }
        bannerViewConstraints.isActive = false
        bannerViewConstraints.removeAll()
        let heightConstraint = bannerView.heightAnchor.constraint(equalToConstant: 44)
        bannerViewConstraints.append(heightConstraint)
        heightConstraint.isActive = true
        let leadingConstraint = bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        bannerViewConstraints.append(leadingConstraint)
        leadingConstraint.isActive = true
        let trailingConstraint = bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        bannerViewConstraints.append(trailingConstraint)
        trailingConstraint.isActive = true
        
        if let previewingTabBar = previewingTabBar, let _ = cardViewController {
            view.bringSubview(toFront: previewingTabBar)
            view.bringSubview(toFront: flexibleTabBar)
            if isHorizontalSizeClassRegular {
                cardViewExpandedCornerRadius = 5
                let bottomConstraint = bannerView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
                bannerViewConstraints.append(bottomConstraint)
                bottomConstraint.isActive = true
            } else {
                cardViewCollapsedCornerRadius = 0
                cardViewExpandedCornerRadius = 0
                let bottomConstraint = bannerView.bottomAnchor.constraint(equalTo: previewingTabBar.topAnchor)
                bannerViewConstraints.append(bottomConstraint)
                bottomConstraint.isActive = true
            }
        } else {
            cardViewCollapsedCornerRadius = 18
            cardViewExpandedCornerRadius = 5
            let bottomConstraint = bannerView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
            bannerViewConstraints.append(bottomConstraint)
            bottomConstraint.isActive = true
        }
        
    }
    
    func removeBannerView() {
        cardViewDestinationY = 55
        isCardViewShadowHidden = false
        bannerView?.removeFromSuperview()
        bannerView = nil
        cardViewCollapsedCornerRadius = 18
        cardViewExpandedCornerRadius = 5
    }
    
    override func transitionIfNeededTo(state: CardState, duration: TimeInterval, completion: (() -> ())?) {
        super.transitionIfNeededTo(state: state, duration: duration) {
            completion?()
            guard state == .collapsed else { return }
            let navigationControllre = (self.viewControllers?[1] as? UINavigationController)
            navigationControllre?.isNavigationBarHidden = true
            navigationControllre?.isNavigationBarHidden = false
        }
    }
    
}

