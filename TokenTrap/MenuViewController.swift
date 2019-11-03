//
//  MenuViewController.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/12/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    var skillLevelIsExpert = false

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
        present(LearnHowViewController(), animated: true, completion: nil)
    }

    func handleTrainTap() {
        print("handleTrainTap")
    }

    func skillLevelDidChange(skillLevelIsExpert: Bool) {
        self.skillLevelIsExpert = skillLevelIsExpert
    }
}

