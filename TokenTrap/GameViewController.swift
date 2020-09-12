//
//  GameViewController.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 11/17/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

enum TokenTapResult {
    case firstSelection(tokenID: TokenID)
    case partialMatch(tDataPair: TokenDataPair)
    case mismatch(tDataPair: TokenDataPair)
    case targetMatch(tDataPair: TokenDataPair, rowsCleared: Int)
}

class MenuButton: UIButton {
    lazy var icon = MenuIcon.standard

    convenience init(gameController: GameViewController,
                     action: Selector) {
        self.init()
        gameController.view.addNoMaskSubviews([self])
        addNoMaskSubviews([icon])
        addTarget(gameController,
                  action: action,
                  for: .touchUpInside)
    }

    func setUpConstraints(gameController: GameViewController) {
        let padding = CGFloat(24)
        NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: icon.frame.size.width + padding),
                                     heightAnchor.constraint(equalToConstant: icon.frame.size.height + padding),
                                     leftAnchor.constraint(equalTo: gameController.view.safeAreaLayoutGuide.leftAnchor),
                                     topAnchor.constraint(equalTo: gameController.view.safeAreaLayoutGuide.topAnchor),
                                     icon.widthAnchor.constraint(equalToConstant: icon.frame.size.width),
                                     icon.heightAnchor.constraint(equalToConstant: icon.frame.size.height),
                                     icon.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     icon.centerYAnchor.constraint(equalTo: centerYAnchor)])
    }
}

typealias MenuClosure = (UIAlertAction) -> Void
extension UIAlertController {
    static func showMenuDialog(gameController: GameViewController,
                               endClosure: @escaping MenuClosure,
                               resumeClosure: @escaping MenuClosure) {

        let pauseController = UIAlertController(title: gameController.gameIsOver ? nil : "Game Paused",
                                                message: nil,
                                                preferredStyle: .actionSheet)

        if let popoverController = pauseController.popoverPresentationController {
            popoverController.sourceView = gameController.view
            popoverController.sourceRect = CGRect(x: gameController.view.bounds.midX,
                                                  y: gameController.view.bounds.midY,
                                                  width: 0,
                                                  height: 0)
            popoverController.permittedArrowDirections = []
        }

        let endGame = UIAlertAction(title: gameController.gameIsOver ? "Main Menu" : "End Game",
                                    style: .destructive,
                                    handler: endClosure)
        let resumeGame = UIAlertAction(title: gameController.gameIsOver ? "Cancel" : "Resume",
                                       style: .default,
                                       handler: resumeClosure)
        pauseController.addAction(endGame)
        pauseController.addAction(resumeGame)
        gameController.present(pauseController,
                               animated: true,
                               completion: nil)
    }
}

enum Constants {
    static let levelRowTarget = 10
    static let addRowCountLimit = 4
    static let gridSize = 8
}

class LevelCompleteLabel: UILabel {

    override func willMove(toSuperview newSuperview: UIView?) {
        font = .systemFont(ofSize: 24,
                           weight: .heavy)
        numberOfLines = 0
        textAlignment = .center
        textColor = .white
    }

    func setUpConstraints(gridView: GridView) {
        NSLayoutConstraint.activate([centerXAnchor.constraint(equalTo: gridView.centerXAnchor),
                                     centerYAnchor.constraint(equalTo: gridView.centerYAnchor)])
    }

    func show(level: Int) {
        text = "Level " + String(level) + "\nComplete!"
        isHidden = false
    }
}

class GameViewController: UIViewController {

    var gameData = GameData()

    var addRowTimer: Timer?
    var addRowTimerInterval = 1.2
    var addRowCount = 1

    var expertModeOn = false
    var trainingModeOn = false
    var gameIsOver = false

    var orientationConstraints = ViewConstraints()

    var menuIsShowing = false {
        didSet {
            gridView.updateForMenuState(isShowing: menuIsShowing)
        }
    }

    lazy var levelView = GameInfoView(type: .level, value: 1)
    lazy var scoreView = GameInfoView(type: .score, value: 0)
    lazy var timerView = TimerView()
    lazy var levelProgressView = LevelProgressView()
    lazy var menuButton = MenuButton(gameController: self,
                                     action: #selector(handleMenuButton))

    lazy var gameOverView: GameOverView = {
        let gameOverView = GameOverView(playAgainAction: handlePlayAgainButton)
        gameOverView.alpha = 0
        view.addNoMaskSubviews([gameOverView])
        gameOverView.setUpConstraints(anchorView: gridView)

        return gameOverView
    }()

    lazy var targetTokenView: TokenView = {
        let targetToken = TokenView()
        targetToken.alpha = 0
        targetToken.backgroundColor = .targetYellow
        targetToken.isUserInteractionEnabled = false
        return targetToken
    }()

    lazy var targetTokenIntroConstraints: [NSLayoutConstraint] = {
        [targetTokenView.centerXAnchor.constraint(equalTo: levelIntroView.centerXAnchor),
         targetTokenView.bottomAnchor.constraint(equalTo: levelIntroView.bottomAnchor,
                                                 constant: -levelIntroView.margin)]
    }()

    lazy var targetTokenFullConstraints: ViewConstraints = {
        let constant = CGFloat(-16)
        var constraints = ViewConstraints()
        constraints.addForOrientation(landscape: [targetTokenView.rightAnchor.constraint(equalTo: timerView.leftAnchor,
                                                                                         constant: constant),
                                                  targetTokenView.centerYAnchor.constraint(equalTo: gridView.centerYAnchor)],
                                      portrait: [targetTokenView.centerXAnchor.constraint(equalTo: gridView.centerXAnchor),
                                                 targetTokenView.bottomAnchor.constraint(equalTo: timerView.topAnchor,
                                                                                         constant: constant)])
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

    lazy var levelCompleteLabel: LevelCompleteLabel = {
        let label = LevelCompleteLabel()
        label.isHidden = true
        return label
    }()

    var viewsToHideOnRotation: [UIView] {
        [timerView,
         targetTokenView,
         levelProgressView]
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background
        view.addNoMaskSubviews([gridView,
                                timerView,
                                levelIntroView,
                                targetTokenView,
                                menuButton,
                                levelProgressView,
                                levelView,
                                scoreView,
                                levelCompleteLabel])
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

    @objc func handlePlayAgainButton() {
        gameIsOver = false
        gameOverView.hide(completion: startGame)
    }

    func startGame() {
        gameData.level = 0
        timerView.update(count: 0)
        startLevel()
    }

    func updateTargetToken() {
        gameData.targetAttributes = (TokenColor.random(), TokenIcon.random())
        targetTokenView.color = gameData.targetAttributes.color
        targetTokenView.icon = gameData.targetAttributes.icon
    }

    func newLevelUIRefresh() {
        levelCompleteLabel.isHidden = true
        levelProgressView.update(count: 0)
        gridView.showBackground()
        levelView.value = gameData.level
        updateTargetToken()
    }

    func startLevel() {
        gameData.levelUp()
        newLevelUIRefresh()
        showLevelIntro()

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(5),
                                      execute: finishLevelStart)
    }

    @objc func finishLevelStart() {
        guard !menuIsShowing else {
            return
        }

        hideLevelIntro(completion: startAddingRows)
    }

    func startAddingRows() {
        addRowCount = 1
        addRow()
        startAddRowTimer()
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
        gridView.addRow(gameData.nextRow())
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
        guard !menuIsShowing else {
            return
        }

        timerView.update(count: addRowCount)

        if addRowCount == Constants.addRowCountLimit {
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
        gameIsOver = true
        addRowTimer?.invalidate()
        timerView.updateForGameOver()
        levelProgressView.update(count: 0)
        gridView.blockTokenTaps()
        gridView.clearGrid()
        gameData.reset()
        gameOverView.renderStats(score: gameData.score,
                                 level: expertModeOn ? .expert : .basic)
    }

    func tokenTapped(tokenID: TokenID) {
        guard let result = gameData.processTokenTap(tokenID: tokenID) else {
            // TODO: end game?
            return
        }

        if case TokenTapResult.targetMatch(_, let rowsCleared) = result {
            levelProgressView.update(count: rowsCleared)

            if gameData.rows.isEmpty {
                resetRowAdding()
            }

            if rowsCleared == Constants.levelRowTarget {
                endLevel()
            }
        }

        gridView.processTokenTapResult(result)
    }

    func resetRowAdding() {
        addRowTimer?.invalidate()
        timerView.update(count: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1),
                                      execute: startAddingRows)
    }

    func endLevel() {
        addRowTimer?.invalidate()
        timerView.update(count: 0)
        gridView.blockTokenTaps()
        levelProgressView.update(count: 10)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1),
                                      execute: flashLevelProgress)
    }

    func flashLevelProgress() {
        levelProgressView.flash(completion: startLevelTransition)
    }

    func startLevelTransition() {
        gridView.clearGrid()
        levelCompleteLabel.show(level: gameData.level)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3),
                                      execute: startLevel)
    }

    @objc func handleMenuButton() {
        menuIsShowing = true

        let endClosure: MenuClosure = { _ in
            self.addRowTimer?.invalidate()
            self.dismiss(animated: true, completion: nil)
        }
        let resumeClosure: MenuClosure = { _ in
            self.menuIsShowing = false
            self.finishLevelStart()
        }
        UIAlertController.showMenuDialog(gameController: self,
                                         endClosure: endClosure,
                                         resumeClosure: resumeClosure)
    }

    func setUpConstraints() {
        setUpGridConstraints()
        setUpTimerConstraints()
        setUpLevelProgressConstraints()
        orientationConstraints.merge(timerView.indicatorConstraints)
        orientationConstraints.merge(levelProgressView.indicatorConstraints)
        setUpIntroConstraints()
        setUpTargetConstraints()
        levelIntroView.setUpConstraints(gridView)
        menuButton.setUpConstraints(gameController: self)
        setUpInfoConstraints()
        orientationConstraints.merge(scoreView.orientationConstraints)
        levelCompleteLabel.setUpConstraints(gridView: gridView)
    }

    func setUpTargetConstraints() {
        let constraints = gridView.tokenSizeConstraints(view: targetTokenView)
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

    func setUpLevelProgressConstraints() {
        orientationConstraints.addForOrientation(landscape: [levelProgressView.leftAnchor.constraint(equalTo: gridView.rightAnchor,
                                                                                                     constant: levelProgressView.weight),
                                                             levelProgressView.rightAnchor.constraint(equalTo: levelProgressView.leftAnchor,
                                                                                                      constant: levelProgressView.weight),
                                                             levelProgressView.topAnchor.constraint(equalTo: gridView.topAnchor),
                                                             levelProgressView.bottomAnchor.constraint(equalTo: gridView.bottomAnchor)],

                                                 portrait: [levelProgressView.leftAnchor.constraint(equalTo: gridView.leftAnchor),
                                                            levelProgressView.rightAnchor.constraint(equalTo: gridView.rightAnchor),
                                                            levelProgressView.topAnchor.constraint(equalTo: gridView.bottomAnchor,
                                                                                                   constant: levelProgressView.weight),
                                                            levelProgressView.bottomAnchor.constraint(equalTo: levelProgressView.topAnchor,
                                                                                                      constant: levelProgressView.weight)])
    }

    func setUpInfoConstraints() {
        let padding = CGFloat(18)
        orientationConstraints.addForOrientation(landscape: [levelView.leftAnchor.constraint(equalTo: levelProgressView.rightAnchor,
                                                                                             constant: padding),
                                                             levelView.bottomAnchor.constraint(equalTo: gridView.bottomAnchor,
                                                                                               constant: -padding),
                                                             scoreView.leftAnchor.constraint(equalTo: levelProgressView.rightAnchor,
                                                                                             constant: padding),
                                                             scoreView.topAnchor.constraint(equalTo: gridView.topAnchor,
                                                                                            constant: padding)],
                                                 portrait: [levelView.topAnchor.constraint(equalTo: levelProgressView.bottomAnchor,
                                                                                           constant: padding),
                                                            levelView.leftAnchor.constraint(equalTo: gridView.leftAnchor,
                                                                                            constant: padding),
                                                            scoreView.topAnchor.constraint(equalTo: levelProgressView.bottomAnchor,
                                                                                           constant: padding),
                                                            scoreView.rightAnchor.constraint(equalTo: gridView.rightAnchor,
                                                                                             constant: -padding)])
    }
}
