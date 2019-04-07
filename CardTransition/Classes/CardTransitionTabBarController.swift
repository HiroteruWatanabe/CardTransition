//
//  CardTransitionTabBarController.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/05.
//  Copyright © 2019 HiroteruWatanabe. All rights reserved.
//

import UIKit

open class CardTransitionTabBarController: UITabBarController {
    
    enum CardState {
        case collapsed
        case expanded
    }
    
    struct LayoutConstraintGroup {
        var constraints: [NSLayoutConstraint]
        var areActive: Bool = false {
            didSet {
                constraints.forEach({ $0.isActive = areActive })
            }
        }
        
        init() {
            self.constraints = []
        }
        
        init(constraints: [NSLayoutConstraint]) {
            self.constraints = constraints
        }
        
        init(constraints: NSLayoutConstraint...) {
            self.constraints = constraints
        }
        
        mutating func removeAll() {
            constraints.removeAll()
        }
        
        mutating func append(_ constraint: NSLayoutConstraint) {
            constraints.append(constraint)
        }
    }
    
    public typealias CardViewController = UIViewController & UIViewControllerCardTransition
    public var isCardViewExpanded: Bool = false
    public var animationThreshold: CGFloat = 0.1
    
    private var animations: [UIViewPropertyAnimator] = []
    private var dimmedView: UIView!
    public var cardViewController: CardViewController?
    private var cardViewExpandedConstraint: NSLayoutConstraint?
    private var cardViewCollapsedConstraint: NSLayoutConstraint?
    var cardViewCornerRadius: CGFloat = 5
    internal var cardViewDestinationY: CGFloat = 55.0
    
    private var animationProgressWhenInterrupted: CGFloat = 0.0
    private var transitionDuration: TimeInterval = 0.3
    
    // MARK: Properties TabBar
    public var flexibleTabBar: FlexibleTabBar!
    public var flexibleTabBarWidth: CGFloat = 375
    private var flexibleTabBarHeightConstraint: NSLayoutConstraint!
    private var flexibleTabBarExpandedConstraints: LayoutConstraintGroup = LayoutConstraintGroup()
    private var flexibleTabBarCollapsedConstraints: LayoutConstraintGroup = LayoutConstraintGroup()
    
    public var previewingTabBar: UITabBar?
    public private(set) var previewingViewHeight: CGFloat = 44
    private var previewingTabBarBottomConstraint: NSLayoutConstraint?
    private var previewingTabBarExpandedConstraintGroup: LayoutConstraintGroup = LayoutConstraintGroup()
    private var previewingTabBarCollapsedConstraintGroup: LayoutConstraintGroup = LayoutConstraintGroup()
    private var previewingTabBarConstraints: LayoutConstraintGroup = LayoutConstraintGroup()
    
    private var previewingBackgroundTabBar: UITabBar?
    private var previewingBackgroundTabBarHeightConstraint: NSLayoutConstraint?
    
    private var isHorizontalSizeClassRegular: Bool {
        return traitCollection.horizontalSizeClass == .regular
    }
    
    private var statusBarStyle: UIStatusBarStyle = .default {
        didSet {
            cardViewController?.statusBarStyle = statusBarStyle
            setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override open var childForStatusBarStyle: UIViewController? {
        return cardViewController
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        dimmedView = UIView()
        view.addSubview(dimmedView)
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        dimmedView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        dimmedView.alpha = isCardViewExpanded ? 1.0 : 0
        
        // MARK: Set up TabBar
        setupFlexibleTabBar()
        
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewingBackgroundTabBar?.layoutSubviews()
    }
    
    override open func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard tabBar == flexibleTabBar else { return }
        for i in 0..<(tabBar.items?.count ?? 0) {
            if self.tabBar.items?[i].tag == item.tag {
                selectedIndex = i
                return
            }
        }
    }
    
    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if traitCollection.horizontalSizeClass != newCollection.horizontalSizeClass {
            transitionIfNeededTo(state: .collapsed, duration: 0)
        }
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard let cardViewController = cardViewController else { return }
        if let previewingView = cardViewController.previewingViewController.view {
            previewingView.layoutIfNeeded()
            if isHorizontalSizeClassRegular {
                previewingViewHeight = max(cardViewController.previewingViewHeight, tabBar.frame.height)
            } else {
                previewingViewHeight = cardViewController.previewingViewHeight
            }
        }
        
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupFlexibleTabBar()
        }
        
        previewingBackgroundTabBarHeightConstraint?.constant = previewingViewHeight
        if !isHorizontalSizeClassRegular {
            previewingTabBarBottomConstraint?.constant = -tabBar.frame.height
        }
        
        previewingTabBar?.layoutIfNeeded()
        previewingBackgroundTabBar?.layoutIfNeeded()
        
        if isHorizontalSizeClassRegular {
            cardViewCornerRadius = 0
        } else {
            cardViewCornerRadius = 5
        }
        
    }
    
    private func setupPreviewingTabBar() {
        let previewingTabBar: UITabBar
        if let tabBar = self.previewingTabBar {
            previewingTabBar = tabBar
        } else {
            previewingTabBar = UITabBar()
            previewingTabBar.barStyle = tabBar.barStyle
            self.previewingTabBar = previewingTabBar
            previewingTabBar.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(previewingTabBar)
        }
        previewingTabBarConstraints.areActive = false
        previewingTabBar.removeConstraints(previewingTabBarConstraints.constraints)
        previewingTabBarConstraints.removeAll()
        previewingTabBarCollapsedConstraintGroup.removeAll()
        previewingTabBarExpandedConstraintGroup.removeAll()
        previewingTabBarBottomConstraint = nil
        
        if isHorizontalSizeClassRegular {
            let leadingConstraint = previewingTabBar.leadingAnchor.constraint(equalTo: flexibleTabBar.trailingAnchor)
            previewingTabBarConstraints.append(leadingConstraint)
            leadingConstraint.isActive = true
            
            let collapsedTopConstraint = previewingTabBar.topAnchor.constraint(equalTo: flexibleTabBar.topAnchor)
            previewingTabBarCollapsedConstraintGroup.append(collapsedTopConstraint)
            previewingTabBarConstraints.append(collapsedTopConstraint)
            previewingTabBarCollapsedConstraintGroup.areActive = true
            
            let expandedTopConstraint = previewingTabBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
            previewingTabBarExpandedConstraintGroup.append(expandedTopConstraint)
            previewingTabBarConstraints.append(expandedTopConstraint)
            previewingTabBarExpandedConstraintGroup.areActive = false
            
            let bottomConstraint = previewingTabBar.bottomAnchor.constraint(equalTo: flexibleTabBar.bottomAnchor)
            previewingTabBarConstraints.append(bottomConstraint)
            bottomConstraint.isActive = true
            
            let trailingConstraint = previewingTabBar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor)
            previewingTabBarConstraints.append(trailingConstraint)
            trailingConstraint.isActive = true
        } else {
            let leadingConstraint = previewingTabBar.leadingAnchor.constraint(equalTo: flexibleTabBar.leadingAnchor)
            previewingTabBarConstraints.append(leadingConstraint)
            leadingConstraint.isActive = true
            
            let trailingConstraint = previewingTabBar.trailingAnchor.constraint(equalTo: flexibleTabBar.trailingAnchor)
            previewingTabBarConstraints.append(trailingConstraint)
            trailingConstraint.isActive = true
            
            let collapsedBottomConstraint = previewingTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -tabBar.frame.height)
            previewingTabBarBottomConstraint = collapsedBottomConstraint
            previewingTabBarConstraints.append(collapsedBottomConstraint)
            previewingTabBarCollapsedConstraintGroup.append(collapsedBottomConstraint)
            
            let collapsedHeightConstraint = previewingTabBar.heightAnchor.constraint(equalToConstant: previewingViewHeight)
            previewingTabBarCollapsedConstraintGroup.append(collapsedHeightConstraint)
            previewingTabBarConstraints.append(collapsedHeightConstraint)
            previewingTabBarCollapsedConstraintGroup.areActive = true
            
            let expandedTopConstraint = previewingTabBar.topAnchor.constraint(equalTo: view.topAnchor, constant: cardViewDestinationY)
            previewingTabBarExpandedConstraintGroup.append(expandedTopConstraint)
            previewingTabBarConstraints.append(expandedTopConstraint)
            let expandedBottomConstraint = previewingTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            previewingTabBarExpandedConstraintGroup.append(expandedBottomConstraint)
            previewingTabBarConstraints.append(expandedBottomConstraint)
            
            previewingTabBar.isHidden = cardViewController == nil
        }
    }
    
    private func setupFlexibleTabBar() {
        tabBar.isHidden = true
        if let flexibleTabbar = flexibleTabBar {
            flexibleTabbar.removeFromSuperview()
        }
        
        flexibleTabBar = FlexibleTabBar()
        flexibleTabBar.barStyle = tabBar.barStyle
        flexibleTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(flexibleTabBar)
        updateFlexibleTabBarConstraints()
        updateFlexibleTabBarItems()
        setupPreviewingTabBar()
        setupPreviewingBackgroundTabBar()
    }
    
    private func updateFlexibleTabBarConstraints() {
        guard let flexibleTabBar = self.flexibleTabBar else { return }
        flexibleTabBarExpandedConstraints.removeAll()
        flexibleTabBarCollapsedConstraints.removeAll()
        
        flexibleTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        
        let collapsedTopConstraint = flexibleTabBar.topAnchor.constraint(equalTo: tabBar.topAnchor)
        flexibleTabBarCollapsedConstraints.append(collapsedTopConstraint)
        collapsedTopConstraint.isActive = true
        
        let collapsedBottomConstraint = flexibleTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        flexibleTabBarCollapsedConstraints.append(collapsedBottomConstraint)
        collapsedBottomConstraint.isActive = true
        
        if isHorizontalSizeClassRegular {
            let expandedTopConstraint = flexibleTabBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -tabBar.frame.height)
            flexibleTabBarExpandedConstraints.append(expandedTopConstraint)
            
            let expandedBottomConstraint = flexibleTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            flexibleTabBarExpandedConstraints.append(expandedBottomConstraint)
        } else {
            let expandedTopConstraint = flexibleTabBar.topAnchor.constraint(equalTo: view.bottomAnchor)
            flexibleTabBarExpandedConstraints.append(expandedTopConstraint)
            let expandedHeightConstraint = flexibleTabBar.heightAnchor.constraint(equalToConstant: tabBar.frame.height)
            flexibleTabBarExpandedConstraints.append(expandedHeightConstraint)
        }
        
        flexibleTabBarHeightConstraint = flexibleTabBar.heightAnchor.constraint(equalToConstant: tabBar.frame.height)
        flexibleTabBarHeightConstraint.isActive = true
        flexibleTabBar.delegate = self
        
        if isHorizontalSizeClassRegular {
            flexibleTabBar.widthAnchor.constraint(equalTo: tabBar.widthAnchor, constant: -flexibleTabBarWidth).isActive = true
            drawTabBarBorder()
        } else {
            flexibleTabBar.widthAnchor.constraint(equalTo: tabBar.widthAnchor, constant: 0).isActive = true
        }
    }
    
    private func drawTabBarBorder() {
        let border = UIView()
        border.backgroundColor = UIColor(white: 0.57, alpha: 0.85)
        border.translatesAutoresizingMaskIntoConstraints = false
        flexibleTabBar.addSubview(border)
        border.trailingAnchor.constraint(equalTo: flexibleTabBar.trailingAnchor).isActive = true
        border.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        border.topAnchor.constraint(equalTo: flexibleTabBar.topAnchor, constant: 4).isActive = true
        border.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
    }
    
    private func updateFlexibleTabBarItems() {
        var itemsForFlexibleTabBar: [UITabBarItem] = []
        for (index, item) in (tabBar.items ?? []).enumerated() {
            guard viewControllers?[index] != cardViewController else { continue }
            item.tag = index
            let title = item.title
            let image = item.image?.copy() as? UIImage
            let tag = item.tag
            let flexibleItem = UITabBarItem(title: title, image: image, tag: tag)
            flexibleItem.selectedImage = item.selectedImage?.copy() as? UIImage
            itemsForFlexibleTabBar.append(flexibleItem)
        }
        flexibleTabBar.setItems(itemsForFlexibleTabBar, animated: false)
        
        if (flexibleTabBar.items?.count ?? 0) > selectedIndex {
            flexibleTabBar.selectedItem = flexibleTabBar.items?[selectedIndex]
        } else {
            flexibleTabBar.selectedItem = flexibleTabBar.items?.first
        }
    }
    
    private func setupPreviewingBackgroundTabBar() {
        guard let previewingView = cardViewController?.previewingViewController.view else { return }
        self.previewingBackgroundTabBar?.removeFromSuperview()
        let previewingBackgroundTabBar = UITabBar()
        self.previewingBackgroundTabBar = previewingBackgroundTabBar
        previewingView.addSubview(previewingBackgroundTabBar)
        previewingView.sendSubviewToBack(previewingBackgroundTabBar)
        previewingBackgroundTabBar.translatesAutoresizingMaskIntoConstraints = false
        previewingBackgroundTabBar.topAnchor.constraint(equalTo: previewingView.topAnchor).isActive = true
        previewingBackgroundTabBar.leadingAnchor.constraint(equalTo: previewingView.leadingAnchor).isActive = true
        previewingBackgroundTabBar.trailingAnchor.constraint(equalTo: previewingView.trailingAnchor).isActive = true
        previewingBackgroundTabBar.heightAnchor.constraint(equalToConstant: previewingViewHeight).isActive = true
        previewingBackgroundTabBarHeightConstraint?.isActive = true
    }
    
    open func setCardViewController(_ cardViewController: CardViewController) {
        guard let previewingView = cardViewController.previewingViewController.view else { return }
        self.cardViewController = cardViewController
        addChild(cardViewController)
        
        if isHorizontalSizeClassRegular {
            previewingViewHeight = max(cardViewController.previewingViewHeight, tabBar.frame.height)
        } else {
            previewingViewHeight = previewingView.frame.height
        }
        setupPreviewingTabBar()
        
        setupPreviewingBackgroundTabBar()
        
        if let previewingTabBar = previewingTabBar {
            previewingTabBar.addSubview(cardViewController.view)
            cardViewController.view.translatesAutoresizingMaskIntoConstraints = false
            cardViewController.view.leadingAnchor.constraint(equalTo: previewingTabBar.leadingAnchor).isActive = true
            cardViewController.view.trailingAnchor.constraint(equalTo: previewingTabBar.trailingAnchor).isActive = true
            
            cardViewController.view.topAnchor.constraint(equalTo: previewingTabBar.topAnchor).isActive = true
            cardViewCollapsedConstraint = cardViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            cardViewCollapsedConstraint?.isActive = true
            cardViewExpandedConstraint = cardViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
            
        }
        cardViewController.didMove(toParent: self)
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestrue(gestureRecognizer:)))
        cardViewController.previewingViewController.view.addGestureRecognizer(tapGestureRecognizer)
        
        let panGetstureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gestureRecognizer:)))
        cardViewController.previewingViewController.view.addGestureRecognizer(panGetstureRecognizer)
        view.bringSubviewToFront(flexibleTabBar)
    }
    
    @objc func handleTapGestrue(gestureRecognizer: UITapGestureRecognizer) {
        transitionIfNeededTo(state: isCardViewExpanded ? .collapsed : .expanded, duration: transitionDuration)
    }
    
    @objc func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: cardViewController?.previewingViewController.view)
        var fractionComplete = translation.y / (view.bounds.height - previewingViewHeight)
        fractionComplete = abs(fractionComplete)
        switch gestureRecognizer.state {
        case .began:
            startTransitionTo(state: isCardViewExpanded ? .collapsed : .expanded, duration: transitionDuration)
        case .changed:
            updateTransition(fractionComplete: fractionComplete)
        case .ended:
            continueTransition(fractionComplete: fractionComplete)
        default:
            break
        }
    }
    
    func startTransitionTo(state: CardState, duration: TimeInterval) {
        if animations.isEmpty {
            transitionIfNeededTo(state: state, duration: duration)
        }
        
        animations.forEach({
            $0.pauseAnimation()
            animationProgressWhenInterrupted = $0.fractionComplete
        })
    }
    
    func updateTransition(fractionComplete: CGFloat) {
        animations.forEach({
            $0.fractionComplete = fractionComplete + animationProgressWhenInterrupted
        })
    }
    
    func continueTransition(fractionComplete: CGFloat) {
        animations.forEach({
            $0.isReversed = fractionComplete <= animationThreshold
            $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        })
    }
    
    func transitionIfNeededTo(state: CardState, duration: TimeInterval, completion: (() -> ())? = nil) {
        guard animations.isEmpty else { return }
        
        animations = []
        let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.cardViewExpandedConstraint?.isActive = true
                self.previewingTabBarExpandedConstraintGroup.areActive = true
                
                self.cardViewCollapsedConstraint?.isActive = false
                self.previewingTabBarCollapsedConstraintGroup.areActive = false
                
                self.view.layoutIfNeeded()
                
            case .collapsed:
                self.cardViewExpandedConstraint?.isActive = false
                self.previewingTabBarExpandedConstraintGroup.areActive = false
                
                self.cardViewCollapsedConstraint?.isActive = true
                self.previewingTabBarCollapsedConstraintGroup.areActive = true
                
                self.view.layoutIfNeeded()
                
            }
        }
        frameAnimator.addCompletion { (position) in
            switch state {
            case .expanded:
                self.isCardViewExpanded = position == .end
            case .collapsed:
                self.isCardViewExpanded = position == .start
            }
            
            self.animations.removeAll()
            
            self.cardViewExpandedConstraint?.isActive = self.isCardViewExpanded
            self.previewingTabBarExpandedConstraintGroup.areActive = self.isCardViewExpanded
            
            self.cardViewCollapsedConstraint?.isActive = !self.isCardViewExpanded
            self.previewingTabBarCollapsedConstraintGroup.areActive = !self.isCardViewExpanded
        }
        frameAnimator.startAnimation()
        animations.append(frameAnimator)
        
        let dimmedViewAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.dimmedView.alpha = 1.0
            case .collapsed:
                self.dimmedView.alpha = 0
            }
        }
        dimmedViewAnimator.startAnimation()
        animations.append(dimmedViewAnimator)
        
        if !isHorizontalSizeClassRegular || state == .collapsed {
            let statusBarAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.statusBarStyle = .lightContent
                case .collapsed:
                    self.statusBarStyle = .default
                }
            }
            statusBarAnimator.startAnimation()
            animations.append(statusBarAnimator)
            
            let transformAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                let scale: CGFloat
                
                switch state {
                case .expanded:
                    scale = 0.94
                case .collapsed:
                    scale = 1.0
                }
                var transform = CATransform3DIdentity
                transform.m34 = 1.0 / -500.0
                transform = CATransform3DScale(transform, scale, scale, 1.0)
                self.selectedViewController?.view.layer.transform = transform
            }
            
            transformAnimator.startAnimation()
            animations.append(transformAnimator)
            
            let roundCornerAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.selectedViewController?.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
                    self.selectedViewController?.view.layer.cornerRadius = self.cardViewCornerRadius
                    self.selectedViewController?.view.layer.masksToBounds = true
                case .collapsed:
                    self.selectedViewController?.view.layer.cornerRadius = 0
                }
            }
            roundCornerAnimator.startAnimation()
            animations.append(roundCornerAnimator)
            
            let tabBarAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.flexibleTabBarExpandedConstraints.areActive = true
                    self.flexibleTabBarCollapsedConstraints.areActive = false
                    self.view.layoutIfNeeded()
                    self.flexibleTabBar.alpha = 0
                    
                case .collapsed:
                    self.flexibleTabBarExpandedConstraints.areActive = false
                    self.flexibleTabBarCollapsedConstraints.areActive = true
                    self.view.layoutIfNeeded()
                    self.flexibleTabBar.alpha = 1
                    
                }
            }
            
            tabBarAnimator.addCompletion { position in
                switch state {
                case .expanded:
                    self.isCardViewExpanded = position == .end
                case .collapsed:
                    self.isCardViewExpanded = position == .start
                }
                self.flexibleTabBarExpandedConstraints.areActive = self.isCardViewExpanded
                self.flexibleTabBarCollapsedConstraints.areActive = !self.isCardViewExpanded
                self.flexibleTabBar.alpha = self.isCardViewExpanded ? 0 : 1
            }
            
            
            tabBarAnimator.startAnimation()
            animations.append(tabBarAnimator)
        }
        
    }
    
}


public protocol UIViewControllerCardTransition {
    
    var previewingViewController: UIViewController! { get set }
    var previewingViewHeight: CGFloat { get }
    var statusBarStyle: UIStatusBarStyle { get set }
}

open class FlexibleTabBar: UITabBar {
    
    override open var traitCollection: UITraitCollection {
        if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isPortrait {
            return UITraitCollection(horizontalSizeClass: .compact)
        }
        return super.traitCollection
    }
    
}

