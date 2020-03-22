//
//  UIExtension.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/13/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import Foundation
import UIKit

struct ViewConstraints {
    var activeConstraints = [NSLayoutConstraint]()
    var landscapeConstraints = [NSLayoutConstraint]()
    var portraitConstraints = [NSLayoutConstraint]()

    mutating func addForOrientation(landscape: [NSLayoutConstraint],
                                    portrait: [NSLayoutConstraint]) {
        landscapeConstraints.append(contentsOf: landscape)
        portraitConstraints.append(contentsOf: portrait)
    }

    mutating func updateForOrientation() {
        let orientation = UIApplication.shared.statusBarOrientation
        let isLandscape = orientation == .landscapeLeft || orientation == .landscapeRight

        if isLandscape {
            update(landscapeConstraints)
        } else {
            update(portraitConstraints)
        }
    }

    mutating func update(_ constraints: [NSLayoutConstraint]) {
        guard constraints != activeConstraints else {
            return
        }

        activeConstraints.forEach { $0.isActive = false }
        activeConstraints.removeAll()
        activeConstraints.append(contentsOf: constraints)
        activeConstraints.forEach { $0.isActive = true }
    }

    mutating func merge(_ source: ViewConstraints) {
        activeConstraints.append(contentsOf: source.activeConstraints)
        landscapeConstraints.append(contentsOf: source.landscapeConstraints)
        portraitConstraints.append(contentsOf: source.portraitConstraints)
    }
}

typealias AnimationItem = (duration: TimeInterval, animation: () -> Void)

extension UIView {

    static func executeAnimationSequence(_ animations: [AnimationItem],
                                         completion: (() -> Void)? = nil) {
        guard let item = animations.first else {

            completion?()

            return
        }

        UIView.animate(withDuration: item.duration,
                       animations: item.animation) { _ in
                        self.executeAnimationSequence(Array(animations.suffix(from: 1)), completion: completion)
        }
    }

    func addNoMaskSubviews(_ views: [UIView]) {
        for view in views {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
    }
}

typealias MenuIcon = UIView
extension MenuIcon {
    static var standard: MenuIcon {
        MenuIcon.renderIcon(barWidth: 28, barHeight: 3)
    }

    static func renderIcon(barWidth: CGFloat,
                           barHeight: CGFloat) -> UIView {
        let icon = MenuIcon()
        icon.isUserInteractionEnabled = false

        for index in 0 ... 2 {
            let bar = UIView(frame: CGRect(x: 0,
                                           y: CGFloat(index) * (2.5 * barHeight),
                                           width: barWidth,
                                           height: barHeight))
            bar.backgroundColor = .white
            bar.layer.cornerRadius = barHeight / 2

            icon.addSubview(bar)

            if index == 2 {
                icon.frame = CGRect(x: 0,
                                    y: 0,
                                    width: barWidth,
                                    height: bar.frame.maxY)
            }
        }

        return icon
    }
}

extension UIColor {
    open class var gold: UIColor {
        UIColor(named: "gold")!
    }
    open class var background: UIColor {
        UIColor(named: "background")!
    }
    open class var buttonBlue: UIColor {
        UIColor(named: "buttonBlue")!
    }
    open class var logoBlue: UIColor {
        UIColor(named: "logoBlue")!
    }
    open class var targetYellow: UIColor {
        UIColor(named: "targetYellow")!
    }
    open class var darkGreen: UIColor {
        UIColor(red: 0, green: 0.35, blue: 0, alpha: 1)
    }
}
