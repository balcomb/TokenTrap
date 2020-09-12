//
//  GameInfoView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 9/7/20.
//  Copyright © 2020 Ben Balcomb. All rights reserved.
//

import UIKit

class GameInfoView: UIView {

    enum GameInfoType {
        case level
        case score
    }

    var type: GameInfoType = .level
    var orientationConstraints = ViewConstraints()

    var value = 0 {
        didSet {
            valueLabel.text = String(value)
        }
    }

    lazy var typeLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 12)
        label.textColor = .init(white: 1, alpha: 0.5)
        addNoMaskSubviews([label])
        return label
    }()

    lazy var valueLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .heavy)
        label.textColor = .white
        addNoMaskSubviews([label])
        return label
    }()

    convenience init(type: GameInfoType, value: Int) {
        self.init()
        self.type = type

        switch type {
        case .level:
            typeLabel.text = "Level".uppercased()
        case .score:
            typeLabel.text = "Score".uppercased()
        }

        valueLabel.text = String(value)
        setUpConstraints()
    }

    func setUpConstraints() {
        var constraints = [typeLabel.leftAnchor.constraint(equalTo: leftAnchor),
                           typeLabel.topAnchor.constraint(equalTo: topAnchor),

                           valueLabel.topAnchor.constraint(equalTo: typeLabel.bottomAnchor),

                           widthAnchor.constraint(greaterThanOrEqualTo: typeLabel.widthAnchor, multiplier: 1),
                           widthAnchor.constraint(greaterThanOrEqualTo: valueLabel.widthAnchor, multiplier: 1),
                           bottomAnchor.constraint(equalTo: valueLabel.bottomAnchor)]

        switch type {
        case .level:
            constraints.append(valueLabel.leftAnchor.constraint(equalTo: leftAnchor))
        case .score:
            orientationConstraints.addForOrientation(landscape: [valueLabel.leftAnchor.constraint(equalTo: leftAnchor)],
                                                     portrait: [valueLabel.rightAnchor.constraint(equalTo: rightAnchor)])
        }

        NSLayoutConstraint.activate(constraints)
    }
}
