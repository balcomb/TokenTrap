//
//  MenuViewController.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/12/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

class MenuViewController: UIViewController {

    var expertModeOn = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let menuView = MenuView(viewController: self)
        view.addNoMaskSubviews([menuView])
        menuView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        menuView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }

    func handlePlayTap() {
        launchGame()
    }

    func handleLearnTap() {
        present(LearnHowViewController(),
                animated: true,
                completion: nil)
    }

    func handleTrainTap() {
        launchGame(trainingModeOn: true)
    }

    func skillLevelDidChange(expertModeOn: Bool) {
        self.expertModeOn = expertModeOn
    }

    func launchGame(trainingModeOn: Bool = false) {
        let gameViewController = GameViewController()
        gameViewController.expertModeOn = expertModeOn
        gameViewController.trainingModeOn = trainingModeOn
        gameViewController.modalPresentationStyle = .fullScreen
        gameViewController.modalTransitionStyle = .flipHorizontal
        present(gameViewController,
                animated: true,
                completion: nil)
    }
}

