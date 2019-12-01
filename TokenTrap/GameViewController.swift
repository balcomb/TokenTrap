//
//  GameViewController.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 11/17/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

class GameViewController: UIViewController {

    var expertModeOn = false
    var trainingModeOn = false
    var orientationConstraints = ViewConstraints()
    lazy var timerView = TimerView()

    lazy var gridView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return view
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.background
        view.addNoMaskSubviews([gridView,
                                timerView])
        setUpConstraints()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        orientationConstraints.updateForOrientation()
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size,
                                 with: coordinator)
        timerView.isHidden = true
        coordinator.animate(alongsideTransition: nil) { _ in
            self.timerView.isHidden = false
        }
    }

    func setUpConstraints() {
        setUpGridConstraints()
        setUpTimerConstraints()
        orientationConstraints.merge(timerView.indicatorConstraints)
    }

    func setUpGridConstraints() {
        if UIDevice.current.userInterfaceIdiom == .pad {
            gridView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
            gridView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

            let multiplier = CGFloat(0.666)
            orientationConstraints.addForOrientation(landscape: [gridView.widthAnchor.constraint(equalTo: gridView.heightAnchor),
                                                                 gridView.heightAnchor.constraint(equalTo: view.heightAnchor,
                                                                                                  multiplier: multiplier)],
                                                     portrait: [gridView.widthAnchor.constraint(equalTo: view.widthAnchor,
                                                                                                multiplier: multiplier),
                                                                gridView.heightAnchor.constraint(equalTo: gridView.widthAnchor)])

            return
        }

        orientationConstraints.addForOrientation(landscape: [gridView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                                                             gridView.topAnchor.constraint(equalTo: view.topAnchor),
                                                             gridView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
                                                             gridView.widthAnchor.constraint(equalTo: gridView.heightAnchor)],

                                                 portrait: [gridView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                                                            gridView.leftAnchor.constraint(equalTo: view.leftAnchor),
                                                            gridView.rightAnchor.constraint(equalTo: view.rightAnchor),
                                                            gridView.heightAnchor.constraint(equalTo: gridView.widthAnchor)])
    }

    func setUpTimerConstraints() {
        orientationConstraints.addForOrientation(landscape: [timerView.leftAnchor.constraint(equalTo: timerView.rightAnchor,
                                                                                             constant: -timerView.weight),
                                                             timerView.rightAnchor.constraint(equalTo: gridView.leftAnchor,
                                                                                              constant: -timerView.weight),
                                                             timerView.topAnchor.constraint(equalTo: gridView.topAnchor),
                                                             timerView.bottomAnchor.constraint(equalTo: gridView.bottomAnchor)],

                                                 portrait: [timerView.leftAnchor.constraint(equalTo: gridView.leftAnchor),
                                                            timerView.rightAnchor.constraint(equalTo: gridView.rightAnchor),
                                                            timerView.topAnchor.constraint(equalTo: timerView.bottomAnchor,
                                                                                           constant: -timerView.weight),
                                                            timerView.bottomAnchor.constraint(equalTo: gridView.topAnchor,
                                                                                              constant: -timerView.weight)])
    }

}
