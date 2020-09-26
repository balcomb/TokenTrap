//
//  TimerView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 11/24/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

class IndicatorView: UIView {

    let weight = CGFloat(4)

    // override in subclasses
    var indicatorCount: Int { 0 }
    var onColor: UIColor { .clear }
    var offColor: UIColor { .clear }

    lazy var indicators: [UIView] = {
        var indicators = [UIView]()

        for index in 0 ..< indicatorCount {
            let indicator = UIView()
            indicator.backgroundColor = offColor
            indicator.layer.cornerRadius = weight / 2.0
            indicators.append(indicator)
        }

        return indicators
    }()

    var indicatorConstraints: ViewConstraints {
        var landscape = [NSLayoutConstraint]()
        var portrait = [NSLayoutConstraint]()
        let multiplier = 1.0 / CGFloat(indicatorCount)
        let gapShift = -(weight + (weight * multiplier))

        for (index, indicator) in indicators.enumerated() {
            let isFirstIndicator = index == 0
            landscape.append(contentsOf: [indicator.leftAnchor.constraint(equalTo: leftAnchor),
                                          indicator.rightAnchor.constraint(equalTo: rightAnchor),
                                          indicator.bottomAnchor.constraint(equalTo: isFirstIndicator ? bottomAnchor : indicators[index - 1].topAnchor,
                                                                            constant: -weight),
                                          indicator.heightAnchor.constraint(equalTo: heightAnchor,
                                                                            multiplier: multiplier,
                                                                            constant: gapShift)])
            portrait.append(contentsOf: [indicator.topAnchor.constraint(equalTo: topAnchor),
                                         indicator.bottomAnchor.constraint(equalTo: bottomAnchor),
                                         indicator.leftAnchor.constraint(equalTo: isFirstIndicator ? leftAnchor : indicators[index - 1].rightAnchor,
                                                                         constant: weight),
                                         indicator.widthAnchor.constraint(equalTo: widthAnchor,
                                                                          multiplier: multiplier,
                                                                          constant: gapShift)])
        }

        var constraints = ViewConstraints()
        constraints.addForOrientation(landscape: landscape,
                                      portrait: portrait)
        return constraints
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super .willMove(toSuperview: newSuperview)

        guard subviews.count == 0 else {
            return
        }

        addNoMaskSubviews(indicators)
    }

    func update(count: Int) {
        for (index, indicator) in indicators.enumerated() {
            indicator.backgroundColor = index < count ? onColor : offColor
        }
    }

    func flash(completion: @escaping () -> Void) {
        let flashSequence = UIView.flashSequence(views: indicators)
        UIView.executeAnimationSequence(flashSequence, completion: completion)
    }
}

class TimerView: IndicatorView {

    override var indicatorCount: Int { Constants.addRowCountLimit }
    override var onColor: UIColor { .green }
    override var offColor: UIColor { .darkGreen }

    func updateForGameOver() {
        indicators.forEach { $0.backgroundColor = .red }
    }
}

class LevelProgressView: IndicatorView {
    override var indicatorCount: Int { Constants.levelRowTarget }
    override var onColor: UIColor { .targetYellow }
    override var offColor: UIColor { .levelProgressOff }
}
