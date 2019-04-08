//
//  SampleViewController1.swift
//  CardTransition_Example
//
//  Created by Hiroteru Watanabe on 2019/04/09.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import UIKit
import CardTransition

class SampleViewController: UIViewController {
    
    @IBAction func touchedUpInsideButton(_ sender: UIButton) {
        guard let tabBarController = tabBarController as? SampleCardTransitionTabBarController else { return }
        if let _ = tabBarController.cardViewController {
            tabBarController.removeCardViewController(animated: true)
        } else {
            if let cardViewController = UIStoryboard(name: "SampleCardViewController", bundle: nil).instantiateViewController(withIdentifier: "SampleCardViewController") as? SampleCardViewController {
                let _ = cardViewController.view
                tabBarController.setCardViewController(cardViewController)
            }
        }
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
