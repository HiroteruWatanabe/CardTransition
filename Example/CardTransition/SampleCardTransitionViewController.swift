//
//  SampleCardTransitionViewController.swift
//  CardTransition_Example
//
//  Created by HiroteruWatanabe on 2019/04/08.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import CardTransition

class SampleCardTransitionViewController: CardTransitionViewController {
    
    @IBAction func touchedUpInsideButton(_ sender: UIButton) {
        if let _ = cardViewController {
            removeCardViewController(animated: true)
        } else {
            if let cardViewController = UIStoryboard(name: "SampleCardViewController2", bundle: nil).instantiateViewController(withIdentifier: "SampleCardViewController2") as? SampleCardViewController2 {
                let _ = cardViewController.view
                
                setCardViewController(cardViewController, heightStyle: .flexible, collapsedHeight: 40, expandedHeight: 400)
            }
        }
    }
    
}
