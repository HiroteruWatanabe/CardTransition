//
//  ViewController.swift
//  CardTransition
//
//  Created by HiroteruWatanabe on 2019/04/05.
//  Copyright © 2019 HiroteruWatanabe. All rights reserved.
//

import UIKit
import CardTransition

class ViewController: CardTransitionTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let cardViewController = UIStoryboard(name: "CardViewController", bundle: nil).instantiateViewController(withIdentifier: "CardViewController") as? CardViewController {
            let _ = cardViewController.view
            setCardViewController(cardViewController)
        }
        
    }
    
}

