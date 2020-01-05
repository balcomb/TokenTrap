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
    var tokenIDCounter = TokenID.counterStart
    var rows = [[TokenData]]()

    var canAddRow: Bool {
        rows.count < GridSize.standard
    }
}

typealias TokenID = Int
extension TokenID {
    static var notSet = -1
    static var counterStart = 0

    mutating func incremented() -> TokenID {
        self += 1
        return self
    }
}

struct TokenData {
    var attributes: TokenAttributes
    var id = TokenID.notSet
}

class GameViewController: UIViewController {

    var gameData = GameData()

    var addRowTimer: Timer?
    var addRowTimerInterval = 1.2
    let addRowCountLimit = 4
    var addRowCount = 1

    var expertModeOn = false
    var trainingModeOn = false
    var orientationConstraints = ViewConstraints()
    lazy var timerView = TimerView()

    lazy var targetTokenView: TokenView = {
        let targetToken = TokenView()
        targetToken.alpha = 0
        targetToken.isUserInteractionEnabled = false
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

    lazy var levelIntroView: LevelIntroView = {
        let view = LevelIntroView()
        let tapGesture = UITapGestureRecognizer.init(target: self,
                                                     action: #selector(finishLevelStart))
        view.addGestureRecognizer(tapGesture)
        return view
    }()

    lazy var gridView: GridView = {
        let view = GridView()
        view.controller = self
        return view
    }()

    var viewsToHideOnRotation: [UIView] {
        [timerView,
         targetTokenView]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background
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

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
            self.finishLevelStart()
        }
    }

    @objc func finishLevelStart() {
        self.hideLevelIntro {
            self.addRow()
            self.startAddRowTimer()
        }
    }

    func showLevelIntro() {
        levelIntroView.updateLevel(gameData.level)
        targetTokenFullConstraints.update(targetTokenIntroConstraints)
        self.view.layoutIfNeeded()
        targetTokenView.alpha = 1

        levelIntroYPositionConstraints.offscreen.isActive = false
        levelIntroYPositionConstraints.onscreen.isActive = true
        animateIntroLevel()
    }

    func hideLevelIntro(completion: @escaping () -> Void) {
        guard levelIntroYPositionConstraints.onscreen.isActive else {
            return
        }

        levelIntroYPositionConstraints.onscreen.isActive = false
        levelIntroYPositionConstraints.offscreen.isActive = true
        targetTokenFullConstraints.updateForOrientation()
        animateIntroLevel(completion: completion)
    }

    func animateIntroLevel(completion: (() -> Void)? = nil) {
        let levelIntroAnimation: AnimationItem = (0.5, {
            self.levelIntroView.alpha = self.levelIntroView.alpha == 0 ? 1 : 0
            self.view.layoutIfNeeded()
        })

        UIView.executeAnimationSequence([levelIntroAnimation]) {
            completion?()
        }
    }

    func addRow() {
        var data = [TokenData]()

        for _ in 0 ..< gridView.gridSize {
            data.append(TokenData(attributes: (TokenColor.random(), TokenIcon.random()),
                                  id: gameData.tokenIDCounter.incremented()))
        }

        gameData.rows.append(data)
        gridView.addRow(data: data)
    }

    func startAddRowTimer() {
        addRowTimer?.invalidate()

        addRowTimer = Timer.scheduledTimer(timeInterval: addRowTimerInterval,
                                           target: self,
                                           selector: #selector(handleAddRowTimer),
                                           userInfo: nil,
                                           repeats: true)
    }

    @objc func handleAddRowTimer() {
        timerView.update(count: addRowCount)

        if addRowCount == addRowCountLimit {
            guard gameData.canAddRow else {
                endGame()
                return
            }

            addRowCount = 0
            addRow()
        } else {
            addRowCount += 1
        }
    }

    func endGame() {
        addRowTimer?.invalidate()
        timerView.updateForGameOver()
        gridView.blockTokenTaps()
        gridView.clearGrid()
        gameData.rows.removeAll()
    }

    func tokenTapped(tokenView: TokenView) {
        print(tokenView.id)
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
