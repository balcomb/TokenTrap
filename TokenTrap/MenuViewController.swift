//
//  MenuViewController.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/12/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    var isExpertMode = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let menuView = MenuView(viewController: self)
        view.addSubview(menuView)
        menuView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        menuView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    func handlePlayTap() {
        print("handlePlayTap")
    }

    func handleLearnTap() {
        print("handleLearnTap")
    }

    func handleTrainTap() {
        print("handleTrainTap")
    }
}

