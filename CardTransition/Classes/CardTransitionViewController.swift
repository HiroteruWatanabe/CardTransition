//
//  CardTransitionViewController.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/08.
//

import UIKit

open class CardTransitionViewController: UIViewController, UIViewControllerCardTransition {
    
    public enum CardViewHeightStyle {
        case flexible
        case fixed
    }
    
    public var isCardViewExpanded: Bool = false {
        didSet {
            cardViewController?.isExpanded = isCardViewExpanded
        }
    }
    public var animationThreshold: CGFloat = 0.1
    public private(set) var animationProgressWhenInterrupted: CGFloat = 0.0
    public var transitionDuration: TimeInterval = 0.3
    
    public var animations: [UIViewPropertyAnimator] = []
    public var dimmedView: UIView!
    public var cardViewController: CardViewController?
    public var cardViewCollapsedHeight: CGFloat = 44
    public var cardViewExpandedHeight: CGFloat = 400
    public var cardViewHeightStyle: CardViewHeightStyle = .flexible
    public var cardViewExpandedConstraint: NSLayoutConstraint?
    public var cardViewCollapsedConstraint: NSLayoutConstraint?
    public private(set) var expandedViewCornerRadius: CGFloat = 8
    
    public var isCardViewPresented: Bool {
        return cardViewController != nil
    }
    
    public var cardViewCornerRadius: CGFloat {
        return isCardViewExpanded ? cardViewExpandedCornerRadius : cardViewCollapsedCornerRadius
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
    
    public var cardViewDestinationY: CGFloat = 55.0
    public var butterflyHandle: ButterflyHandle?
    public private(set) var cardViewPreviewingViewHeight: CGFloat = 44
    public var hidesPreviewingViewWhenExpanded: Bool = true
    public var gestureResponder: UIView?
    
    public var isCardViewShadowHidden: Bool = false {
        didSet {
            setupCardViewShadow()
        }
    }
    
    open func setupCardViewShadow() {
        guard !isCardViewShadowHidden else {
            cardViewController?.view.layer.shadowOpacity = 0
            return
        }
        guard let cardViewController = cardViewController else { return }
        cardViewController.view.layer.shadowColor = UIColor.black.cgColor
        cardViewController.view.layer.shadowOffset = .zero
        cardViewController.view.layer.shadowRadius = 3
        cardViewController.view.layer.shadowOpacity = 0.25
        cardViewController.view.layer.masksToBounds = false
    }
    
    open func setCardViewController(_ cardViewController: CardViewController) {
        setCardViewController(cardViewController, heightStyle: .flexible, collapsedHeight: 44, expandedHeight: 400)
    }
    
    open func setCardViewController(_ cardViewController: CardViewController, heightStyle: CardViewHeightStyle, collapsedHeight: CGFloat, expandedHeight: CGFloat) {
        cardViewHeightStyle = heightStyle
        cardViewCollapsedHeight = collapsedHeight
        cardViewExpandedHeight = expandedHeight
        if cardViewController.view.frame.height <= view.frame.height - cardViewDestinationY {
            cardViewDestinationY = view.frame.height - cardViewController.view.frame.height
        } else {
            cardViewDestinationY = 55.0
        }
        self.cardViewController = cardViewController
        cardViewController.view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardViewController.view.layer.masksToBounds = true
        cardViewController.view.layer.cornerRadius = cardViewCornerRadius
        
        addChild(cardViewController)
        
        cardViewPreviewingViewHeight = cardViewController.previewingViewHeight
        
        let butterflyHandle = ButterflyHandle()
        self.butterflyHandle = butterflyHandle
        
        butterflyHandle.widthAnchor.constraint(equalToConstant: butterflyHandle.frame.width).isActive = true
        butterflyHandle.heightAnchor.constraint(equalToConstant: butterflyHandle.frame.height).isActive = true
        butterflyHandle.translatesAutoresizingMaskIntoConstraints = false
        cardViewController.view.addSubview(butterflyHandle)
        butterflyHandle.topAnchor.constraint(equalTo: cardViewController.view.topAnchor, constant: 8).isActive = true
        butterflyHandle.centerXAnchor.constraint(equalTo: cardViewController.view.centerXAnchor).isActive = true
        butterflyHandle.setSelected(true, animated: false)
        
        view.addSubview(cardViewController.view)
        cardViewController.view.translatesAutoresizingMaskIntoConstraints = false
        switch heightStyle {
        case .flexible:
            cardViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
            cardViewCollapsedConstraint = cardViewController.view.heightAnchor.constraint(equalToConstant: cardViewCollapsedHeight)
            cardViewExpandedConstraint = cardViewController.view.heightAnchor.constraint(equalToConstant: cardViewExpandedHeight)
        case .fixed:
            cardViewController.view.heightAnchor.constraint(equalToConstant: cardViewExpandedHeight).isActive = true
            cardViewCollapsedConstraint = cardViewController.view.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -cardViewCollapsedHeight)
            cardViewExpandedConstraint = cardViewController.view.topAnchor.constraint(equalTo: view.bottomAnchor, constant: -cardViewExpandedHeight)
        }
        
        cardViewCollapsedConstraint?.isActive = true
        cardViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        cardViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        
        cardViewController.didMove(toParent: self)
        
        let previewingView = cardViewController.previewingViewController?.view
        var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestrue(gestureRecognizer:)))
        previewingView?.addGestureRecognizer(tapGestureRecognizer)
        
        var panGetstureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gestureRecognizer:)))
        previewingView?.addGestureRecognizer(panGetstureRecognizer)
        
        let gestureResponder = UIView()
        self.gestureResponder = gestureResponder
        gestureResponder.translatesAutoresizingMaskIntoConstraints = false
        if let previewingView = cardViewController.previewingViewController?.view {
            cardViewController.view.insertSubview(gestureResponder, belowSubview: previewingView)
        } else {
            cardViewController.view.insertSubview(gestureResponder, belowSubview: butterflyHandle)
        }
        gestureResponder.topAnchor.constraint(equalTo: cardViewController.view.topAnchor).isActive = true
        gestureResponder.leadingAnchor.constraint(equalTo: cardViewController.view.leadingAnchor).isActive = true
        gestureResponder.trailingAnchor.constraint(equalTo: cardViewController.view.trailingAnchor).isActive = true
        gestureResponder.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGestrue(gestureRecognizer:)))
        gestureResponder.addGestureRecognizer(tapGestureRecognizer)
        panGetstureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(gestureRecognizer:)))
        gestureResponder.addGestureRecognizer(panGetstureRecognizer)
        
        setupCardViewShadow()
    }
    
    open func removeCardViewController(animated: Bool, completion: (() -> ())? = nil) {
        if isCardViewExpanded {
            transitionIfNeededTo(state: .collapsed, duration: animated ? transitionDuration : 0) { [weak self] in
                self?.cardViewController?.willMove(toParent: nil)
                self?.cardViewController?.view.removeFromSuperview()
                self?.cardViewController?.removeFromParent()
                self?.cardViewController = nil
                self?.butterflyHandle?.removeFromSuperview()
                completion?()
            }
        } else {
            cardViewController?.willMove(toParent: nil)
            cardViewController?.view.removeFromSuperview()
            cardViewController?.removeFromParent()
            cardViewController = nil
            butterflyHandle?.removeFromSuperview()
            completion?()
        }
    }
    
    public func updateCardViewCornerRadius() {
        guard let cardView = cardViewController?.view else { return }
        cardView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        cardView.layer.masksToBounds = true
        cardView.layer.cornerRadius = cardViewCornerRadius
    }
    
    
    @objc public func handleTapGestrue(gestureRecognizer: UITapGestureRecognizer) {
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
    
    open func collapseCardViewController(animated: Bool) {
        guard isCardViewExpanded else { return }
        cardViewController?.didStartTransitionTo(state: .collapsed, fractionComplete: 0, animationDuration: animated ? transitionDuration : 0)
        transitionIfNeededTo(state: .collapsed, duration: animated ? transitionDuration : 0)
    }
    
    open func startTransitionTo(state: CardState, duration: TimeInterval) {
        if animations.isEmpty {
            transitionIfNeededTo(state: state, duration: duration)
        }
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
    
    open func transitionIfNeededTo(state: CardState, duration: TimeInterval, completion: (() -> ())? = nil) {
        guard animations.isEmpty else { return }
        
        animations = []
        
        let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
            switch state {
            case .expanded:
                self.cardViewCollapsedConstraint?.isActive = false
                self.cardViewExpandedConstraint?.isActive = true
                if self.hidesPreviewingViewWhenExpanded {
                    self.cardViewController?.previewingViewController?.view.alpha = 0
                }
                self.cardViewController?.view.layer.cornerRadius = self.cardViewExpandedCornerRadius
                self.view.layoutIfNeeded()
                
            case .collapsed:
                self.cardViewExpandedConstraint?.isActive = false
                self.cardViewCollapsedConstraint?.isActive = true
                self.cardViewController?.previewingViewController?.view.alpha = 1
                self.cardViewController?.view.layer.cornerRadius = self.cardViewCollapsedCornerRadius
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
            
            if self.isCardViewExpanded {
                self.cardViewCollapsedConstraint?.isActive = false
                self.cardViewExpandedConstraint?.isActive = true
            } else {
                self.cardViewExpandedConstraint?.isActive = false
                self.cardViewCollapsedConstraint?.isActive = true
            }
            
            self.cardViewController?.didEndTransitionTo(state: state, fractionComplete: self.isCardViewExpanded ? 1.0 : 0.0, animationThreshold: self.animationThreshold)
            completion?()
        }
        frameAnimator.startAnimation()
        animations.append(frameAnimator)
        
    }
}
