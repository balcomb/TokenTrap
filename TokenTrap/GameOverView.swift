//
//  GameOverView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 1/26/20.
//  Copyright © 2020 Ben Balcomb. All rights reserved.
//

import UIKit

class GameOverView: UIView {

    lazy var gameOverLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gold
        label.font = .boldSystemFont(ofSize: 22)
        return label
    }()

    lazy var finalScoreLabel: UILabel = {
        let label = UILabel()
        label.text = "Final Score"
        label.textColor = .logoBlue
        return label
    }()

    lazy var scoreLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 44)
        return label
    }()

    lazy var averageScoreLabel: UILabel = {
        genericAverageLabel()
    }()

    lazy var personalAverageLabel: UILabel = {
        genericAverageLabel()
    }()

    lazy var playAgainButton: PlayButton = {
        let button = PlayButton(title: "Play Again")
        button.addTarget(self,
                         action: #selector(handlePlayAgainButton),
                         for: .touchUpInside)
        return button
    }()

    var playAgainAction: (() -> Void)?

    convenience init(playAgainAction: @escaping () -> Void) {
        self.init()
        self.playAgainAction = playAgainAction
    }

    @objc func handlePlayAgainButton() {
        playAgainAction?()
    }

    func genericAverageLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor(white: 0.9,
                                  alpha: 1)
        return label
    }

    func setUpConstraints(anchorView: UIView) {
        guard subviews.count == 0 else { return }

        addNoMaskSubviews([gameOverLabel,
                           finalScoreLabel,
                           scoreLabel,
                           personalAverageLabel,
                           playAgainButton])

        let playAgainPadding = CGFloat(24)
        NSLayoutConstraint.activate([leftAnchor.constraint(equalTo: anchorView.leftAnchor),
                                     rightAnchor.constraint(equalTo: anchorView.rightAnchor),
                                     topAnchor.constraint(equalTo: anchorView.topAnchor),
                                     bottomAnchor.constraint(equalTo: anchorView.bottomAnchor),

                                     scoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     scoreLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

                                     finalScoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     finalScoreLabel.bottomAnchor.constraint(equalTo: scoreLabel.topAnchor),

                                     gameOverLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     gameOverLabel.bottomAnchor.constraint(equalTo: finalScoreLabel.topAnchor,
                                                                           constant: -gameOverLabel.font.pointSize),

                                     personalAverageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     personalAverageLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor,
                                                                               constant: personalAverageLabel.font.pointSize / 2),

                                     playAgainButton.leftAnchor.constraint(equalTo: leftAnchor,
                                                                           constant: playAgainPadding),
                                     playAgainButton.rightAnchor.constraint(equalTo: rightAnchor,
                                                                            constant: -playAgainPadding),
                                     playAgainButton.heightAnchor.constraint(equalToConstant: PlayButton.height),
                                     playAgainButton.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                                             constant: -playAgainPadding)])
    }

    func renderStats(score: Int, level: SkillLevel) {

        if StatData.isPersonalBest(score: score, level: level) {
            gameOverLabel.text = "New Personal Best!"
        } else {
            gameOverLabel.text = "Game Over"
        }

        scoreLabel.text = String(score)
        personalAverageLabel.text = averageLabelText(level: level,
                                                     score: StatData.updatedPersonalAverage(score: score,
                                                                                            level: level))
        fade(alpha: 1)
    }

    func hide(completion: @escaping () -> Void) {
        fade(alpha: 0) {
            completion()
        }
    }

    func fade(alpha: CGFloat, completion: (() -> Void)? = nil) {
        let fade: AnimationItem = (0.5, {
            self.alpha = alpha
        })
        UIView.executeAnimationSequence([fade]) {
            completion?()
        }
    }

    func averageLabelText(level: SkillLevel,
                          score: Double) -> String {
        guard StatData.isValidAverageScore(score) else {
            return ""
        }

        let levelText = (level == .basic ? "Basic" : "Expert") + " Level"
        let scoreText = String(format: "%.1f", score)

        return "Your " + levelText + " Average: "  + scoreText
    }
}
