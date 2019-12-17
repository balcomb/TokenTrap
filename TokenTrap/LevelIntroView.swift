//
//  LevelIntroView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 12/15/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

class LevelIntroView: UIView {

    let targetTokenSize = CGFloat(44)
    let margin = CGFloat(22)
    let padding = CGFloat(8)

    lazy var levelLabel: UILabel = {
        let label = UILabel()
        label.text = "Level X"
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = UIColor.white

        return label
    }()

    lazy var targetLabel: UILabel = {
        let label = UILabel()
        label.text = "Target"
        label.font = UIFont.boldSystemFont(ofSize: 12)
        label.textColor = UIColor(white: 1,
                                  alpha: 0.6)
        return label
    }()

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        guard subviews.count == 0 else {
            return
        }

        setUpStyle()
        addNoMaskSubviews([levelLabel,
                           targetLabel])
        setUpConstraints()
    }

    func updateLevel(_ level: Int) {
        levelLabel.text = "Level " + String(level)
    }

    func setUpStyle() {
        alpha = 0
        backgroundColor = UIColor.background
        layer.cornerRadius = 8
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
    }

    func setUpConstraints() {
        let constraints = [levelLabel.topAnchor.constraint(equalTo: topAnchor,
                                                           constant: margin),
                           levelLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                           targetLabel.topAnchor.constraint(equalTo: levelLabel.bottomAnchor,
                                                            constant: padding),
                           targetLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
                           bottomAnchor.constraint(equalTo: targetLabel.bottomAnchor,
                                                   constant: targetTokenSize + margin + padding),
                           widthAnchor.constraint(equalTo: heightAnchor)]
        constraints.forEach { $0.isActive = true }
    }
}
