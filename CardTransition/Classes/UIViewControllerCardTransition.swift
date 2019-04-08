//
//  UIViewControllerCardTransition.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/08.
//

import UIKit

public enum CardState {
    case collapsed
    case expanded
}

public typealias CardViewController = UIViewController & UIViewControllerCardTransitionable

public protocol UIViewControllerCardTransition {
    
    var isCardViewExpanded: Bool { get }
    var animationThreshold: CGFloat { get set }
    var animationProgressWhenInterrupted: CGFloat { get }
    var transitionDuration: TimeInterval { get }
    
    var animations: [UIViewPropertyAnimator] { get }
    var dimmedView: UIView! { get }
    var cardViewController: CardViewController? { get }
    var isCardViewPresented: Bool { get }
    
    var cardViewExpandedConstraint: NSLayoutConstraint? { get }
    var cardViewCollapsedConstraint: NSLayoutConstraint? { get }
    var expandedViewCornerRadius: CGFloat { get }
    var cardViewCornerRadius: CGFloat { get }
    var cardViewCollapsedCornerRadius: CGFloat { get }
    var cardViewExpandedCornerRadius: CGFloat { get }
    var cardViewDestinationY: CGFloat { get }
    var butterflyHandle: ButterflyHandle? { get }
    var hidesPreviewingViewWhenExpanded: Bool { get set }
    var gestureResponder: UIView? { get }
    
    func setupCardViewShadow()
    var isCardViewShadowHidden: Bool { get set }
    
    func setCardViewController(_ cardViewController: CardViewController)
    func removeCardViewController(animated: Bool, completion: (() -> ())?)
    func updateCardViewCornerRadius()
    
    func handleTapGestrue(gestureRecognizer: UITapGestureRecognizer)
    func handlePanGesture(gestureRecognizer: UIPanGestureRecognizer)
    
    func collapseCardViewController(animated: Bool)
    func startTransitionTo(state: CardState, duration: TimeInterval)
    func updateTransition(fractionComplete: CGFloat)
    func continueTransition(fractionComplete: CGFloat)
    func transitionIfNeededTo(state: CardState, duration: TimeInterval, completion: (() -> ())?)
}
