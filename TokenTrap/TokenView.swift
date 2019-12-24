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
        [TokenIcon.die,
         TokenIcon.face,
         TokenIcon.star].randomElement()!
    }
}

enum TokenColor: String {
    case blue = "iconBlue"
    case gray = "iconGray"
    case red = "iconRed"
    case notSet

    static func random() -> TokenColor {
        [TokenColor.blue,
         TokenColor.gray,
         TokenColor.red].randomElement()!
    }
}

class TokenView: UIView {

    var id = TokenID.notSet

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

    lazy var iconView = UIImageView()

    convenience init(_ attributes: TokenAttributes) {
        self.init()
        DispatchQueue.main.async {
            self.color = attributes.color
            self.icon = attributes.icon
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.size.height / 2

        guard subviews.count == 0 else {
            return
        }

        backgroundColor = UIColor.white
        addNoMaskSubviews([iconView])
        setUpConstraints()
    }

    func setUpConstraints() {
        let multiplier = CGFloat(0.6)
        let constraints = [iconView.widthAnchor.constraint(equalTo: widthAnchor,
                                                           multiplier: multiplier),
                           iconView.heightAnchor.constraint(equalTo: heightAnchor,
                                                            multiplier: multiplier),
                           iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
                           iconView.centerYAnchor.constraint(equalTo: centerYAnchor)]
        constraints.forEach { $0.isActive = true }
    }

}
