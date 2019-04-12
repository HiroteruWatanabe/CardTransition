//
//  CardTransitionTabBarController.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/05.
//  Copyright © 2019 HiroteruWatanabe. All rights reserved.
//

import UIKit

open class CardTransitionTabBarController: UITabBarController, UIViewControllerCardTransition {
    
    override open var viewControllers: [UIViewController]? {
        set {
            guard let cardViewController = cardViewController else { return super.viewControllers = newValue }
            super.viewControllers = newValue?.filter({ $0 != cardViewController })
        }
        get {
            guard let cardViewController = cardViewController else { return super.viewControllers }
            return super.viewControllers?.filter({ $0 != cardViewController })
        }
    }
    
    public var isCardViewExpanded: Bool = false {
        didSet {
            cardViewController?.isExpanded = isCardViewExpanded
            gestureResponder?.isUserInteractionEnabled = isCardViewExpanded
        }
    }
    public var animationThreshold: CGFloat = 0.1
    public private(set) var animationProgressWhenInterrupted: CGFloat = 0.0
    public var transitionDuration: TimeInterval = 0.3
    
    public var animations: [UIViewPropertyAnimator] = []
    public var dimmedView: UIView!
    public var cardViewController: CardViewController?
    public var cardViewExpandedConstraint: NSLayoutConstraint?
    public var cardViewCollapsedConstraint: NSLayoutConstraint?
    public private(set) var expandedViewCornerRadius: CGFloat = 5
    public var isCardViewPresented: Bool {
        return cardViewController != nil
    }
    
    public var cardViewCornerRadius: CGFloat {
        if isHorizontalSizeClassRegular {
            return isCardViewExpanded ? cardViewExpandedCornerRadius : 0
        } else {
            return isCardViewExpanded ? cardViewExpandedCornerRadius : cardViewCollapsedCornerRadius
        }
    }
    
    public var cardViewCollapsedCornerRadius: CGFloat = 18 {
        didSet {
            updateCardViewCornerRadius()
        }
    }
    public var cardViewExpandedCornerRadius: CGFloat = 5 {
        didSet {
            updateCardViewCornerRadius()
        }
    }
    
    public var isCardViewShadowHidden: Bool = false {
        didSet {
            setupCardViewShadow()
        }
    }
    
    public var cardViewDestinationY: CGFloat = 55.0 {
        didSet {
            previewingTabBarExpandedTopConstraint?.constant = cardViewDestinationY
        }
    }
    public var butterflyHandle: ButterflyHandle?
    public var hidesButterflyHandleWhenCollapsed: Bool = false {
        didSet {
            guard !isCardViewExpanded else { return }
            butterflyHandle?.alpha = hidesButterflyHandleWhenCollapsed ? 0 : 1
        }
    }
    private var longPressGestureStartPoint: CGPoint = .zero
    public var hidesPreviewingViewWhenExpanded: Bool = true
    public var gestureResponder: UIView?
    public var cardViewPreviewingViewHeight: CGFloat = 44
    
    // MARK: Properties TabBar
    public var flexibleTabBar: FlexibleTabBar!
    public var flexibleTabBarWidthWhenHorizontalSizeClassRegular: CGFloat = 375 {
        didSet {
            guard isHorizontalSizeClassRegular else { return }
            guard flexibleTabBarWidthWhenHorizontalSizeClassRegular != oldValue else { return }
            updateFlexibleTabBarConstraints()
        }
    }
    private var flexibleTabBarConstraintGroup: LayoutConstraintGroup = LayoutConstraintGroup()
    private var flexibleTabBarExpandedConstraintGroup: LayoutConstraintGroup = LayoutConstraintGroup()
    private var flexibleTabBarCollapsedConstraintGroup: LayoutConstraintGroup = LayoutConstraintGroup()
    
    public var previewingTabBar: UITabBar!
    private var previewingTabBarBottomConstraint: NSLayoutConstraint?
    private var previewingTabBarExpandedTopConstraint: NSLayoutConstraint?
    private var previewingTabBarExpandedConstraintGroup: LayoutConstraintGroup = LayoutConstraintGroup()
    private var previewingTabBarCollapsedConstraintGroup: LayoutConstraintGroup = LayoutConstraintGroup()
    private var previewingTabBarConstraints: LayoutConstraintGroup = LayoutConstraintGroup()
    
    private var previewingBackgroundTabBar: UITabBar?
    private var previewingBackgroundTabBarHeightConstraint: NSLayoutConstraint?
    
    var isHorizontalSizeClassRegular: Bool {
        return traitCollection.horizontalSizeClass == .regular
    }
    
    open var statusBarStyle: UIStatusBarStyle = .default {
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
        
        setupDimmedView()
        setupFlexibleTabBar()
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewingBackgroundTabBar?.layoutSubviews()
    }
    
    override open func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard tabBar == flexibleTabBar else { return }
        guard let items = tabBar.items else { return }
        for i in 0..<items.count {
            if items[i].tag == item.tag {
                selectedIndex = i
                return
            }
        }
    }
    
    override open func addChild(_ childController: UIViewController) {
        let viewControllers = self.viewControllers
        super.addChild(childController)
        if childController == cardViewController {
            self.viewControllers = viewControllers
        }
    }
    
    override open func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        if traitCollection.horizontalSizeClass != newCollection.horizontalSizeClass {
            guard let cardViewController = cardViewController else { return }
            temporaryRemoveCardViewController()
            previewingTabBar.addSubview(cardViewController.view)
            setupCardViewConstraints()
            setupButterflyHandle()
            setupGestureResponder()
        }
    }
    
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        if let cardViewController = cardViewController,
            let previewingView = cardViewController.previewingViewController?.view {
            previewingView.layoutIfNeeded()
            if isHorizontalSizeClassRegular {
                cardViewPreviewingViewHeight = max(cardViewController.previewingViewHeight, tabBar.frame.height)
            } else {
                cardViewPreviewingViewHeight = cardViewController.previewingViewHeight
            }
        }
        
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            setupFlexibleTabBar()
            if let cardViewController = cardViewController {
                setCardViewController(cardViewController, isExpanded: isCardViewExpanded)
                updateView()
            }
            updateCardViewCornerRadius()
            setupCardViewShadow()
            if isCardViewExpanded {
                cardViewController?.didStartTransitionTo(state: .expanded, fractionComplete: 1, animationDuration: 0)
            }
        }
        
        previewingBackgroundTabBarHeightConstraint?.constant = cardViewPreviewingViewHeight
        
        previewingTabBar.layoutIfNeeded()
        previewingBackgroundTabBar?.layoutIfNeeded()
        
        if isHorizontalSizeClassRegular {
            expandedViewCornerRadius = 0
        } else {
            expandedViewCornerRadius = 5
        }
        
        if isCardViewExpanded, let selectedViewController = selectedViewController {
            roundCorner(view: selectedViewController.view, cornerRadius: expandedViewCornerRadius)
        }
        
    }
    
    private func setupDimmedView() {
        dimmedView = UIView()
        view.addSubview(dimmedView)
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        dimmedView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        dimmedView.bottomAnchor.constraint(equalTo: tabBar.topAnchor).isActive = true
        dimmedView.alpha = isCardViewExpanded ? 1.0 : 0
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDimmedViewTapGesture(gestureRecognizer:)))
        dimmedView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func handleDimmedViewTapGesture(gestureRecognizer: UITapGestureRecognizer) {
        collapseCardViewController(animated: true)
    }
    
    private func setupPreviewingTabBar() {
        
        if let previewingTabBar = self.previewingTabBar {
            previewingTabBar.removeFromSuperview()
        }
        let previewingTabBar = UITabBar()
        self.previewingTabBar = previewingTabBar
        previewingTabBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(previewingTabBar)
        
        if isHorizontalSizeClassRegular {
            previewingTabBar.barStyle = tabBar.barStyle
            previewingTabBar.isTranslucent = tabBar.isTranslucent
        } else {
            previewingTabBar.backgroundImage = UIImage()
            previewingTabBar.shadowImage = UIImage()
            previewingTabBar.barTintColor = .clear
            previewingTabBar.isTranslucent = true
        }
        previewingTabBarConstraints.isActive = false
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
            
            let expandedTopConstraint = previewingTabBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 0)
            previewingTabBarExpandedConstraintGroup.append(expandedTopConstraint)
            previewingTabBarConstraints.append(expandedTopConstraint)
            
            let bottomConstraint = previewingTabBar.bottomAnchor.constraint(equalTo: flexibleTabBar.bottomAnchor)
            previewingTabBarConstraints.append(bottomConstraint)
            bottomConstraint.isActive = true
            
            let trailingConstraint = previewingTabBar.trailingAnchor.constraint(equalTo: tabBar.trailingAnchor)
            previewingTabBarConstraints.append(trailingConstraint)
            trailingConstraint.isActive = true
            previewingTabBar.isHidden = false
        } else {
            let leadingConstraint = previewingTabBar.leadingAnchor.constraint(equalTo: flexibleTabBar.leadingAnchor)
            previewingTabBarConstraints.append(leadingConstraint)
            leadingConstraint.isActive = true
            
            let trailingConstraint = previewingTabBar.trailingAnchor.constraint(equalTo: flexibleTabBar.trailingAnchor)
            previewingTabBarConstraints.append(trailingConstraint)
            trailingConstraint.isActive = true
            
            let collapsedBottomConstraint = previewingTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            previewingTabBarBottomConstraint = collapsedBottomConstraint
            previewingTabBarConstraints.append(collapsedBottomConstraint)
            previewingTabBarCollapsedConstraintGroup.append(collapsedBottomConstraint)
            
            let collapsedHeightConstraint = previewingTabBar.heightAnchor.constraint(equalToConstant: cardViewPreviewingViewHeight + tabBar.frame.height)
            previewingTabBarCollapsedConstraintGroup.append(collapsedHeightConstraint)
            previewingTabBarConstraints.append(collapsedHeightConstraint)
            
            let expandedTopConstraint = previewingTabBar.topAnchor.constraint(equalTo: view.topAnchor, constant: cardViewDestinationY)
            previewingTabBarExpandedTopConstraint = expandedTopConstraint
            previewingTabBarExpandedConstraintGroup.append(expandedTopConstraint)
            previewingTabBarConstraints.append(expandedTopConstraint)
            let expandedBottomConstraint = previewingTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            previewingTabBarExpandedConstraintGroup.append(expandedBottomConstraint)
            previewingTabBarConstraints.append(expandedBottomConstraint)
            
            previewingTabBar.isHidden = cardViewController == nil
        }
        if isCardViewExpanded {
            previewingTabBarExpandedConstraintGroup.isActive = true
        } else {
            previewingTabBarCollapsedConstraintGroup.isActive = true
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
        flexibleTabBarConstraintGroup.isActive = false
        flexibleTabBarExpandedConstraintGroup.isActive = false
        flexibleTabBarCollapsedConstraintGroup.isActive = false
        flexibleTabBar.removeConstraints(flexibleTabBarConstraintGroup.constraints)
        flexibleTabBarConstraintGroup.removeAll()
        flexibleTabBarExpandedConstraintGroup.removeAll()
        flexibleTabBarCollapsedConstraintGroup.removeAll()
        
        let leadingConstraint = flexibleTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        flexibleTabBarConstraintGroup.append(leadingConstraint)
        leadingConstraint.isActive = true
        
        let collapsedTopConstraint = flexibleTabBar.topAnchor.constraint(equalTo: tabBar.topAnchor)
        flexibleTabBarConstraintGroup.append(collapsedTopConstraint)
        flexibleTabBarCollapsedConstraintGroup.append(collapsedTopConstraint)
        
        let collapsedBottomConstraint = flexibleTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        flexibleTabBarConstraintGroup.append(collapsedBottomConstraint)
        flexibleTabBarCollapsedConstraintGroup.append(collapsedBottomConstraint)
        
        if isHorizontalSizeClassRegular {
            let expandedTopConstraint = flexibleTabBar.topAnchor.constraint(equalTo: tabBar.topAnchor)
            flexibleTabBarConstraintGroup.append(expandedTopConstraint)
            flexibleTabBarExpandedConstraintGroup.append(expandedTopConstraint)
            
            let expandedBottomConstraint = flexibleTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            flexibleTabBarConstraintGroup.append(expandedBottomConstraint)
            flexibleTabBarExpandedConstraintGroup.append(expandedBottomConstraint)
        } else {
            let expandedTopConstraint = flexibleTabBar.topAnchor.constraint(equalTo: view.bottomAnchor)
            flexibleTabBarConstraintGroup.append(expandedTopConstraint)
            flexibleTabBarExpandedConstraintGroup.append(expandedTopConstraint)
            let expandedHeightConstraint = flexibleTabBar.heightAnchor.constraint(equalToConstant: tabBar.frame.height)
            flexibleTabBarConstraintGroup.append(expandedHeightConstraint)
            flexibleTabBarExpandedConstraintGroup.append(expandedHeightConstraint)
        }
        
        flexibleTabBar.delegate = self
        
        if isHorizontalSizeClassRegular {
            let widthConstraint = flexibleTabBar.widthAnchor.constraint(equalTo: tabBar.widthAnchor, constant: -flexibleTabBarWidthWhenHorizontalSizeClassRegular)
            flexibleTabBarConstraintGroup.append(widthConstraint)
            widthConstraint.isActive = true
            drawTabBarBorder()
        } else {
            let widthConstraint = flexibleTabBar.widthAnchor.constraint(equalTo: tabBar.widthAnchor, constant: 0)
            flexibleTabBarConstraintGroup.append(widthConstraint)
            widthConstraint.isActive = true
        }
        
        if isCardViewExpanded {
            flexibleTabBarExpandedConstraintGroup.isActive = true
        } else {
            flexibleTabBarCollapsedConstraintGroup.isActive = true
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
        let a = viewControllers
        let ji = tabBar.items
        for (index, item) in (tabBar.items ?? []).enumerated() {
            guard (viewControllers?.count ?? 0) > index else { break }
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
        guard let previewingView = cardViewController?.previewingViewController?.view else { return }
        previewingView.backgroundColor = .clear
        self.previewingBackgroundTabBar?.removeFromSuperview()
        let previewingBackgroundTabBar = UITabBar()
        previewingBackgroundTabBar.layer.borderWidth = 0
        previewingBackgroundTabBar.clipsToBounds = true
        self.previewingBackgroundTabBar = previewingBackgroundTabBar
        previewingBackgroundTabBar.isUserInteractionEnabled = false
        previewingView.addSubview(previewingBackgroundTabBar)
        previewingView.sendSubviewToBack(previewingBackgroundTabBar)
        previewingBackgroundTabBar.translatesAutoresizingMaskIntoConstraints = false
        previewingBackgroundTabBar.topAnchor.constraint(equalTo: previewingView.topAnchor).isActive = true
        previewingBackgroundTabBar.leadingAnchor.constraint(equalTo: previewingView.leadingAnchor).isActive = true
        previewingBackgroundTabBar.trailingAnchor.constraint(equalTo: previewingView.trailingAnchor).isActive = true
        previewingBackgroundTabBar.heightAnchor.constraint(equalToConstant: cardViewPreviewingViewHeight).isActive = true
        previewingBackgroundTabBarHeightConstraint?.isActive = true
    }
    
    open func setupCardViewShadow() {
        if isCardViewShadowHidden || isHorizontalSizeClassRegular {
            previewingTabBar.layer.shadowOpacity = 0.0
            previewingTabBar.clipsToBounds = false
        } else {
            previewingTabBar.layer.shadowColor = UIColor.black.cgColor
            previewingTabBar.layer.shadowOffset = .zero
            previewingTabBar.layer.shadowRadius = 3
            previewingTabBar.layer.shadowOpacity = 0.25
            previewingTabBar.layer.masksToBounds = false
        }
    }
    
    open func setCardViewController(_ cardViewController: CardViewController, isExpanded: Bool) {
        guard let previewingView = cardViewController.previewingViewController?.view else { return }
        self.cardViewController = cardViewController
        addChild(cardViewController)
        
        if isHorizontalSizeClassRegular {
            cardViewPreviewingViewHeight = max(cardViewController.previewingViewHeight, tabBar.frame.height)
        } else {
            cardViewPreviewingViewHeight = cardViewController.previewingViewHeight
        }
        isCardViewExpanded = isExpanded
        setupPreviewingTabBar()
        setupPreviewingBackgroundTabBar()
        
        setupButterflyHandle()
        
        previewingTabBar.addSubview(cardViewController.view)
        setupCardViewConstraints()
        
        updateCardViewCornerRadius()
        
        cardViewController.didMove(toParent: self)
        setupGestureRecognizers(view: previewingView)
        setupGestureResponder()
        gestureResponder?.isUserInteractionEnabled = isCardViewExpanded
        
        view.bringSubviewToFront(flexibleTabBar)
        setupCardViewShadow()
    }
    
    open func setCardViewController(_ cardViewController: CardViewController) {
        setCardViewController(cardViewController, isExpanded: false)
    }
    
    private func setupCardViewConstraints() {
        guard let cardViewController = cardViewController else { return }
        cardViewExpandedConstraint?.isActive = false
        cardViewCollapsedConstraint?.isActive = false
        cardViewController.view.translatesAutoresizingMaskIntoConstraints = false
        cardViewController.view.leadingAnchor.constraint(equalTo: previewingTabBar.leadingAnchor).isActive = true
        cardViewController.view.trailingAnchor.constraint(equalTo: previewingTabBar.trailingAnchor).isActive = true
        
        cardViewController.view.topAnchor.constraint(equalTo: previewingTabBar.topAnchor).isActive = true
        cardViewCollapsedConstraint = cardViewController.view.heightAnchor.constraint(equalToConstant: cardViewController.view.frame.height)
        cardViewExpandedConstraint = cardViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        
        if isCardViewExpanded {
            cardViewExpandedConstraint?.isActive = true
        } else {
            cardViewCollapsedConstraint?.isActive = true
        }
    }
    
    private func setupButterflyHandle() {
        guard let cardViewController = cardViewController else { return }
        self.butterflyHandle?.removeFromSuperview()
        let butterflyHandle = ButterflyHandle()
        self.butterflyHandle = butterflyHandle
        butterflyHandle.widthAnchor.constraint(equalToConstant: butterflyHandle.frame.width).isActive = true
        butterflyHandle.heightAnchor.constraint(equalToConstant: butterflyHandle.frame.height).isActive = true
        butterflyHandle.translatesAutoresizingMaskIntoConstraints = false
        cardViewController.view.addSubview(butterflyHandle)
        butterflyHandle.topAnchor.constraint(equalTo: cardViewController.view.topAnchor, constant: 8).isActive = true
        butterflyHandle.centerXAnchor.constraint(equalTo: cardViewController.view.centerXAnchor).isActive = true
        
        butterflyHandle.setSelected(true, animated: false)
        if hidesButterflyHandleWhenCollapsed, !isCardViewExpanded {
            butterflyHandle.alpha = 0
        } else {
            butterflyHandle.alpha = 1
        }
    }
    
    private func setupGestureResponder() {
        guard let cardViewController = cardViewController else { return }
        guard let previewingView = cardViewController.previewingViewController?.view else { return }
        self.gestureResponder?.removeFromSuperview()
        let gestureResponder = UIView()
        self.gestureResponder = gestureResponder
        gestureResponder.translatesAutoresizingMaskIntoConstraints = false
        cardViewController.view.insertSubview(gestureResponder, belowSubview: previewingView)
        gestureResponder.topAnchor.constraint(equalTo: cardViewController.view.topAnchor).isActive = true
        gestureResponder.leadingAnchor.constraint(equalTo: cardViewController.view.leadingAnchor).isActive = true
        gestureResponder.trailingAnchor.constraint(equalTo: cardViewController.view.trailingAnchor).isActive = true
        gestureResponder.heightAnchor.constraint(equalToConstant: 66).isActive = true
        
        setupGestureRecognizers(view: gestureResponder)
    }
    
    private func temporaryRemoveCardViewController() {
        cardViewController?.view.removeFromSuperview()
    }
    
    open func removeCardViewController(animated: Bool, completion: (() -> ())? = nil) {
        if isCardViewExpanded {
            transitionIfNeededTo(state: .collapsed, duration: animated ? transitionDuration : 0) { [weak self] in
                self?.cardViewController?.willMove(toParent: nil)
                self?.cardViewController?.view.removeFromSuperview()
                self?.cardViewController?.removeFromParent()
                self?.cardViewController = nil
                self?.butterflyHandle?.removeFromSuperview()
                if self?.isHorizontalSizeClassRegular == false {
                    self?.previewingTabBar.isHidden = true
                }
                completion?()
            }
        } else {
            cardViewController?.willMove(toParent: nil)
            cardViewController?.view.removeFromSuperview()
            cardViewController?.removeFromParent()
            cardViewController = nil
            butterflyHandle?.removeFromSuperview()
            if !isHorizontalSizeClassRegular {
                previewingTabBar.isHidden = true
            }
            completion?()
        }
    }
    
    private func setupGestureRecognizers(view: UIView) {
        view.gestureRecognizers?.forEach({ view.removeGestureRecognizer($0) })
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestrue(gestureRecognizer:)))
        view.addGestureRecognizer(tapGestureRecognizer)
        
        let panGetstureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gestureRecognizer:)))
        view.addGestureRecognizer(panGetstureRecognizer)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture(gestureRecognizer:)))
        view.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    public func updateCardViewCornerRadius() {
        guard let cardView = cardViewController?.view else { return }
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.layer.masksToBounds = cardViewCornerRadius != 0
        cardView.layer.cornerRadius = cardViewCornerRadius
    }
    
    @objc public func handleTapGestrue(gestureRecognizer: UITapGestureRecognizer) {
        butterflyHandle?.setSelected(true, animated: false)
        cardViewController?.didStartTransitionTo(state: isCardViewExpanded ? .collapsed : .expanded, fractionComplete: 0, animationDuration: transitionDuration)
        transitionIfNeededTo(state: isCardViewExpanded ? .collapsed : .expanded, duration: transitionDuration)
    }
    
    @objc public func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: cardViewController?.previewingViewController?.view)
        var fractionComplete = translation.y / (view.bounds.height - cardViewPreviewingViewHeight)
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
    
    @objc public func handleLongPressGesture(gestureRecognizer: UILongPressGestureRecognizer) {
        
        let location = gestureRecognizer.location(in: view)
        let translation = CGPoint(x: location.x - longPressGestureStartPoint.x, y: location.y - longPressGestureStartPoint.y)
        var fractionComplete = translation.y / (view.bounds.height - cardViewPreviewingViewHeight)
        fractionComplete = abs(fractionComplete)
        switch gestureRecognizer.state {
        case .began:
            longPressGestureStartPoint = gestureRecognizer.location(in: view)
            startTransitionTo(state: isCardViewExpanded ? .collapsed : .expanded, duration: transitionDuration)
            updateTransition(fractionComplete: 0)
        case .changed:
            updateTransition(fractionComplete: fractionComplete)
        case .ended:
            continueTransition(fractionComplete: fractionComplete)
        default:
            break
        }
    }
    
    open func collapseCardViewController(animated: Bool) {
        guard isCardViewExpanded else { return }
        cardViewController?.didStartTransitionTo(state: .collapsed, fractionComplete: 0, animationDuration: animated ? transitionDuration : 0)
        transitionIfNeededTo(state: .collapsed, duration: animated ? transitionDuration : 0)
    }
    
    open func expandCardViewController(animated: Bool) {
        guard !isCardViewExpanded else { return }
        butterflyHandle?.setSelected(true, animated: false)
        cardViewController?.didStartTransitionTo(state: .expanded, fractionComplete: 0, animationDuration: animated ? transitionDuration : 0)
        transitionIfNeededTo(state: .expanded, duration: animated ? transitionDuration : 0)
    }
    
    open func startTransitionTo(state: CardState, duration: TimeInterval) {
        if animations.isEmpty {
            transitionIfNeededTo(state: state, duration: duration)
        }
        butterflyHandle?.isSelected = true
        animations.forEach({
            $0.pauseAnimation()
            animationProgressWhenInterrupted = $0.fractionComplete
        })
        cardViewController?.didStartTransitionTo(state: state, fractionComplete: isCardViewExpanded ? 1.0 : 0, animationDuration: duration)
    }
    
    open func updateTransition(fractionComplete: CGFloat) {
        animations.forEach({
            $0.fractionComplete = fractionComplete + animationProgressWhenInterrupted
        })
        cardViewController?.didUpdateTransition(fractionComplete: fractionComplete + animationProgressWhenInterrupted)
    }
    
    open func continueTransition(fractionComplete: CGFloat) {
        animations.forEach({
            $0.isReversed = fractionComplete <= animationThreshold
            $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        })
        cardViewController?.continueTransition(fractionComplete: fractionComplete, animationThreshold: animationThreshold)
    }
    
    private func updateView() {
        if isCardViewExpanded {
            if self.hidesPreviewingViewWhenExpanded {
                self.cardViewController?.previewingViewController?.view.alpha = 0
            }
            self.butterflyHandle?.alpha = 1
            if !self.isHorizontalSizeClassRegular {
                self.cardViewController?.view.layer.cornerRadius = self.cardViewExpandedCornerRadius
            }
            self.dimmedView.alpha = 1.0
            if isHorizontalSizeClassRegular {
                self.statusBarStyle = .default
                if let selectedView = self.selectedViewController?.view {
                    resizeView(selectedView, scale: 1.0)
                    roundCorner(view: selectedView, cornerRadius: 0)
                }
                self.flexibleTabBar.alpha = 1
            } else {
                self.statusBarStyle = .lightContent
                if let selectedView = self.selectedViewController?.view {
                    resizeView(selectedView, scale: 0.94)
                    roundCorner(view: selectedView, cornerRadius: self.expandedViewCornerRadius)
                }
                self.flexibleTabBar.alpha = 0
            }
        } else {
            self.cardViewController?.previewingViewController?.view.alpha = 1
            if self.hidesButterflyHandleWhenCollapsed {
                self.butterflyHandle?.alpha = 0
            }
            if !self.isHorizontalSizeClassRegular {
                self.cardViewController?.view.layer.cornerRadius = self.cardViewCollapsedCornerRadius
            }
            self.dimmedView.alpha = 0
            if isHorizontalSizeClassRegular {
                self.statusBarStyle = .default
                if let selectedView = self.selectedViewController?.view {
                    resizeView(selectedView, scale: 1.0)
                    roundCorner(view: selectedView, cornerRadius: 0)
                }
                self.flexibleTabBar.alpha = 1
            } else {
                self.statusBarStyle = .default
                if let selectedView = self.selectedViewController?.view {
                    resizeView(selectedView, scale: 1.0)
                    roundCorner(view: selectedView, cornerRadius: 0)
                }
                self.flexibleTabBar.alpha = 1
            }
        }
    }
    
    open func transitionIfNeededTo(state: CardState, duration: TimeInterval, completion: (() -> ())? = nil) {
        guard animations.isEmpty else { return }
        
        animations = []
        let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.cardViewCollapsedConstraint?.isActive = false
                self.previewingTabBarCollapsedConstraintGroup.isActive = false
                
                self.cardViewExpandedConstraint?.isActive = true
                self.previewingTabBarExpandedConstraintGroup.isActive = true
                
                if self.hidesPreviewingViewWhenExpanded {
                    self.cardViewController?.previewingViewController?.view.alpha = 0
                }
                self.butterflyHandle?.alpha = 1
                if !self.isHorizontalSizeClassRegular {
                    self.cardViewController?.view.layer.cornerRadius = self.cardViewExpandedCornerRadius
                }
                self.view.layoutIfNeeded()
                
            case .collapsed:
                self.cardViewExpandedConstraint?.isActive = false
                self.previewingTabBarExpandedConstraintGroup.isActive = false
                
                self.cardViewCollapsedConstraint?.isActive = true
                self.previewingTabBarCollapsedConstraintGroup.isActive = true
                
                self.cardViewController?.previewingViewController?.view.alpha = 1
                if self.hidesButterflyHandleWhenCollapsed {
                    self.butterflyHandle?.alpha = 0
                }
                if !self.isHorizontalSizeClassRegular {
                    self.cardViewController?.view.layer.cornerRadius = self.cardViewCollapsedCornerRadius
                }
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
            self.butterflyHandle?.isSelected = !self.isCardViewExpanded
            self.animations.removeAll()
            
            if self.isCardViewExpanded {
                self.cardViewCollapsedConstraint?.isActive = false
                self.previewingTabBarCollapsedConstraintGroup.isActive = false
                
                self.cardViewExpandedConstraint?.isActive = true
                self.previewingTabBarExpandedConstraintGroup.isActive = true
            } else {
                self.cardViewExpandedConstraint?.isActive = false
                self.previewingTabBarExpandedConstraintGroup.isActive = false
                
                self.cardViewCollapsedConstraint?.isActive = true
                self.previewingTabBarCollapsedConstraintGroup.isActive = true
            }
            
            self.updateCardViewCornerRadius()
            self.cardViewController?.didEndTransitionTo(state: state, fractionComplete: self.isCardViewExpanded ? 1.0 : 0.0, animationThreshold: self.animationThreshold)
            completion?()
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
            statusBarAnimator.addCompletion { (position) in
                switch state {
                case .expanded:
                    self.statusBarStyle = position == .start ? .default : .lightContent
                case .collapsed:
                    self.statusBarStyle = position == .start ? .lightContent : .default
                }
            }
            statusBarAnimator.startAnimation()
            animations.append(statusBarAnimator)
            
            let transformAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                guard let view = self.selectedViewController?.view else { return }
                let scale: CGFloat
                
                switch state {
                case .expanded:
                    scale = 0.94
                case .collapsed:
                    scale = 1.0
                }
                self.resizeView(view, scale: scale)
            }
            transformAnimator.startAnimation()
            animations.append(transformAnimator)
            
            let roundCornerAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                if let selectedView = self.selectedViewController?.view {
                    switch state {
                    case .expanded:
                        self.roundCorner(view: selectedView, cornerRadius: self.expandedViewCornerRadius)
                    case .collapsed:
                        self.roundCorner(view: selectedView, cornerRadius: 0)
                    }
                }
                
            }
            roundCornerAnimator.startAnimation()
            animations.append(roundCornerAnimator)
            
            let tabBarAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.flexibleTabBarCollapsedConstraintGroup.isActive = false
                    self.flexibleTabBarExpandedConstraintGroup.isActive = true
                    self.view.layoutIfNeeded()
                    self.flexibleTabBar.alpha = 0
                    
                case .collapsed:
                    self.flexibleTabBarExpandedConstraintGroup.isActive = false
                    self.flexibleTabBarCollapsedConstraintGroup.isActive = true
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
                if self.isCardViewExpanded {
                    self.flexibleTabBarCollapsedConstraintGroup.isActive = false
                    self.flexibleTabBarExpandedConstraintGroup.isActive = true
                } else {
                    self.flexibleTabBarExpandedConstraintGroup.isActive = false
                    self.flexibleTabBarCollapsedConstraintGroup.isActive = true
                }
                self.flexibleTabBar.alpha = self.isCardViewExpanded ? 0 : 1
            }
            tabBarAnimator.startAnimation()
            animations.append(tabBarAnimator)
        }
        
    }
    
    private func resizeView(_ view: UIView, scale: CGFloat) {
        var transform = CATransform3DIdentity
        transform.m34 = 1.0 / -500.0
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        view.layer.transform = transform
    }
    
    private func roundCorner(view: UIView, cornerRadius: CGFloat) {
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.cornerRadius = cornerRadius
        view.layer.masksToBounds = true
    }
}


