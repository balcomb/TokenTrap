//
//  TokenView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 12/17/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

typealias TokenAttributes = (color: TokenColor, icon: TokenIcon)

enum TokenIcon: String {
    case die = "iconDie"
    case face = "iconFace"
    case star = "iconStar"
    case notSet

    static func random() -> TokenIcon {
        [.die,
         .face,
         .star].randomElement()!
    }

    static func iconSet() -> Set<TokenIcon> {
        [.die, .face, .star]
    }
}

enum TokenColor: String {
    case blue = "iconBlue"
    case gray = "iconGray"
    case red = "iconRed"
    case notSet

    static func random() -> TokenColor {
        [.blue,
         .gray,
         .red].randomElement()!
    }

    static func colorSet() -> Set<TokenColor> {
        [.blue, .gray, .red]
    }
}

enum TokenHighlight {
    case selected
    case mismatch
    case targetMatch
    case normal
    case trainingHelper
}

class TokenView: UIView {

    var id = TokenID.notSet

    var attributes: TokenAttributes = (TokenColor.notSet, TokenIcon.notSet) {
        didSet {
            color = attributes.color
            icon = attributes.icon
        }
    }

    var icon = TokenIcon.notSet {
        didSet {
            iconView.image = UIImage(named: icon.rawValue)?.withRenderingMode(.alwaysTemplate)
        }
    }

    var color = TokenColor.notSet {
        didSet {
            iconView.tintColor = UIColor(named: color.rawValue)
        }
    }

    var highlight = TokenHighlight.normal {
        didSet {
            switch highlight {
            case .selected:
                backgroundColor = .selectedGreen
            case .mismatch:
                backgroundColor = .mismatchRed
            case .targetMatch:
                backgroundColor = .targetYellow
            case .normal:
                backgroundColor = .white
            case .trainingHelper:
                backgroundColor = .trainingOrange
            }
        }
    }

    lazy var iconView = UIImageView()
    lazy var iconBaseSizeConstraints = iconSizeConstraints()
    lazy var iconBigSizeConstraints = iconSizeConstraints(multiplier: 0.8)

    var isWildcard = false {
        didSet {
            iconView.isHidden = isWildcard
            wildcardIcon.isHidden = !isWildcard
        }
    }
    lazy var wildcardIcon: UILabel = {
        let wildcard = UILabel()
        wildcard.text = "?"
        wildcard.textColor = .wildcardPurple
        wildcard.isHidden = true
        return wildcard
    }()

    convenience init(_ attributes: TokenAttributes) {
        self.init()
        backgroundColor = .white
        DispatchQueue.main.async {
            self.color = attributes.color
            self.icon = attributes.icon
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2
        wildcardIcon.font = UIFont(name: "AmericanTypewriter-Bold",
                                   size: frame.size.height * 0.8)

        guard subviews.count == 0 else {
            return
        }

        addNoMaskSubviews([iconView,
                           wildcardIcon])
        setUpConstraints()
    }

    func update(withData tData: TokenData,
                highlight: TokenHighlight = .normal,
                completion: (() -> Void)? = nil) {

        attributes = tData.attributes
        self.highlight = highlight
        animateIconChange {
            completion?()
        }
    }

    func iconSizeConstraints(multiplier: CGFloat = 0.6) -> [NSLayoutConstraint] {
        [iconView.widthAnchor.constraint(equalTo: widthAnchor,
                                         multiplier: multiplier),
         iconView.heightAnchor.constraint(equalTo: heightAnchor,
                                          multiplier: multiplier)]
    }

    func setUpConstraints() {
        var constraints = iconBaseSizeConstraints
        [iconView, wildcardIcon].forEach {
            constraints.append(contentsOf: [$0.centerXAnchor.constraint(equalTo: centerXAnchor),
                                            $0.centerYAnchor.constraint(equalTo: centerYAnchor)])
        }
        NSLayoutConstraint.activate(constraints)
    }

    func animateIconChange(completion: (() -> Void)? = nil) {
        isWildcard = false
        iconBaseSizeConstraints.forEach { $0.isActive = false }
        iconBigSizeConstraints.forEach { $0.isActive = true }

        let growIcon: AnimationItem = (0.2, {
            self.layoutIfNeeded()
        })
        let restoreIcon: AnimationItem = (0.2, {
            self.iconBigSizeConstraints.forEach { $0.isActive = false }
            self.iconBaseSizeConstraints.forEach { $0.isActive = true }
            self.layoutIfNeeded()
        })
        UIView.executeAnimationSequence([growIcon, restoreIcon],
                                        completion: completion)
    }
}
