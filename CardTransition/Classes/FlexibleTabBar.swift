//
//  FlexibleTabBar.swift
//  CardTransition
//
//  Created by Hiroteru Watanabe on 2019/04/07.
//

import UIKit

open class FlexibleTabBar: UITabBar {
    
    override open var traitCollection: UITraitCollection {
        if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isPortrait {
            return UITraitCollection(horizontalSizeClass: .compact)
        }
        return super.traitCollection
    }
    
}
