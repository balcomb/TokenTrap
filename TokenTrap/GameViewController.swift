//
//  GameViewController.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 11/17/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

struct GameData {
    var level = 0
    var score = 0
}

class GameViewController: UIViewController {

    var gameData = GameData()

    var expertModeOn = false
    var trainingModeOn = false
    var orientationConstraints = ViewConstraints()
    lazy var timerView = TimerView()

    lazy var targetTokenView: TokenView = {
        let targetToken = TokenView()
        targetToken.alpha = 0
        return targetToken
    }()

    lazy var targetTokenIntroConstraints: [NSLayoutConstraint] = {
        [targetTokenView.centerXAnchor.constraint(equalTo: levelIntroView.centerXAnchor),
         targetTokenView.bottomAnchor.constraint(equalTo: levelIntroView.bottomAnchor,
                                                 constant: -levelIntroView.margin)]
    }()

    lazy var targetTokenFullConstraints: ViewConstraints = {
        var constraints = ViewConstraints()
        constraints.addForOrientation(landscape: [targetTokenView.rightAnchor.constraint(equalTo: timerView.leftAnchor,
                                                                                         constant: -levelIntroView.targetTokenSize),
                                                  targetTokenView.centerYAnchor.constraint(equalTo: gridView.centerYAnchor)],
                                      portrait: [targetTokenView.centerXAnchor.constraint(equalTo: gridView.centerXAnchor),
                                                 targetTokenView.bottomAnchor.constraint(equalTo: timerView.topAnchor,
                                                                                         constant: -levelIntroView.targetTokenSize)])
        return constraints
    }()

    lazy var levelIntroYPositionConstraints: (offscreen: NSLayoutConstraint, onscreen: NSLayoutConstraint) = {
        (levelIntroView.topAnchor.constraint(equalTo: view.bottomAnchor),
         levelIntroView.centerYAnchor.constraint(equalTo: gridView.centerYAnchor))
    }()

    lazy var levelIntroView = LevelIntroView()

    lazy var gridView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        return view
    }()

    var viewsToHideOnRotation: [UIView] {
        [timerView,
         targetTokenView]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.background
        view.addNoMaskSubviews([gridView,
                                timerView,
                                levelIntroView,
                                targetTokenView])
        setUpConstraints()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if gameData.level < 1 {
            startGame()
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        orientationConstraints.updateForOrientation()

        if targetTokenFullConstraints.activeConstraints != targetTokenIntroConstraints {
            targetTokenFullConstraints.updateForOrientation()
        }
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size,
                                 with: coordinator)

        viewsToHideOnRotation.forEach { $0.isHidden = true }

        coordinator.animate(alongsideTransition: nil) { _ in
            self.viewsToHideOnRotation.forEach { $0.isHidden = false }
        }
    }

    func startGame() {
        startLevel()
    }

    func updateTargetToken() {
        targetTokenView.color = TokenColor.random()
        targetTokenView.icon = TokenIcon.random()
    }

    func startLevel() {
        gameData.level += 1
        updateTargetToken()
        showLevelIntro()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(3)) {
            self.hideLevelIntro()
        }
    }

    func showLevelIntro() {
        levelIntroView.updateLevel(gameData.level)
        targetTokenFullConstraints.update(targetTokenIntroConstraints)
        self.view.layoutIfNeeded()
        targetTokenView.alpha = 1
        animateIntroLevel(show: true)
    }

    func hideLevelIntro() {
        animateIntroLevel(show: false)
    }

    func animateIntroLevel(show: Bool) {
        if show {
            levelIntroYPositionConstraints.offscreen.isActive = false
            levelIntroYPositionConstraints.onscreen.isActive = true
        } else {
            levelIntroYPositionConstraints.onscreen.isActive = false
            levelIntroYPositionConstraints.offscreen.isActive = true
            targetTokenFullConstraints.updateForOrientation()
        }

        let levelIntroAnimation = UIView.animationItem(duration: 0.5) {
            self.levelIntroView.alpha = show ? 1 : 0
            self.view.layoutIfNeeded()
        }
        UIView.executeAnimationSequence([levelIntroAnimation])
    }

    func setUpConstraints() {
        setUpGridConstraints()
        setUpTimerConstraints()
        orientationConstraints.merge(timerView.indicatorConstraints)
        setUpIntroConstraints()
        setUpTargetConstraints()
    }

    func setUpTargetConstraints() {
        let constraints = [targetTokenView.widthAnchor.constraint(equalToConstant: levelIntroView.targetTokenSize),
                           targetTokenView.heightAnchor.constraint(equalToConstant: levelIntroView.targetTokenSize)]
        constraints.forEach { $0.isActive = true }
    }

    func setUpIntroConstraints() {
        let constraints = [levelIntroView.centerXAnchor.constraint(equalTo: gridView.centerXAnchor),
                           levelIntroYPositionConstraints.offscreen]
        constraints.forEach { $0.isActive = true }
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
