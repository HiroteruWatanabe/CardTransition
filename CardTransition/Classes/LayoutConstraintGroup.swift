//
//  LayoutConstraintGroup.swift
//  CardTransition
//
//  Created by Hiroteru Watanabe on 2019/04/07.
//

import Foundation

public struct LayoutConstraintGroup {
    public var constraints: [NSLayoutConstraint]
    public var areActive: Bool = false {
        didSet {
            constraints.forEach({ $0.isActive = areActive })
        }
    }
    
    public init() {
        self.constraints = []
    }
    
    public init(constraints: [NSLayoutConstraint]) {
        self.constraints = constraints
    }
    
    public init(constraints: NSLayoutConstraint...) {
        self.constraints = constraints
    }
    
    public mutating func removeAll() {
        constraints.removeAll()
    }
    
    public mutating func append(_ constraint: NSLayoutConstraint) {
        constraints.append(constraint)
    }
}
