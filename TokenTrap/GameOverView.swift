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
                           averageScoreLabel,
                           personalAverageLabel])

        let constraints = [leftAnchor.constraint(equalTo: anchorView.leftAnchor),
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

                           averageScoreLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                           averageScoreLabel.topAnchor.constraint(equalTo: scoreLabel.bottomAnchor,
                                                                  constant: gameOverLabel.font.pointSize),

                           personalAverageLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                           personalAverageLabel.topAnchor.constraint(equalTo: averageScoreLabel.bottomAnchor)]

        constraints.forEach { $0.isActive = true }
    }

    func renderStats(score: Int,
                     statData: StatData) {

        if score >= statData.highScore {
            gameOverLabel.text = "New High Score!"
        } else if StatData.isPersonalBest(score: score, level: statData.level) {
            gameOverLabel.text = "New Personal Best!"
        } else {
            gameOverLabel.text = "Game Over"
        }

        scoreLabel.text = String(score)
        averageScoreLabel.text = averageLabelText(level: statData.level,
                                                  forPersonal: false,
                                                  score: statData.averageScore)
        personalAverageLabel.text = averageLabelText(level: statData.level,
                                                     forPersonal: true,
                                                     score: StatData.updatedPersonalAverage(score: score,
                                                                                            level: statData.level))
        let fadeIn: AnimationItem = (0.5, {
            self.alpha = 1
        })
        UIView.executeAnimationSequence([fadeIn])
    }

    func averageLabelText(level: SkillLevel,
                          forPersonal: Bool,
                          score: Double) -> String {
        guard StatData.isValidAverageScore(score) else {
            return ""
        }

        let mainText = " Average Score: " + String(format: "%.1f", score)

        if forPersonal {
            return "Your" + mainText
        }

        let levelText = (level == .basic ? "Basic" : "Expert") + " Level"

        return levelText + mainText
    }
}
