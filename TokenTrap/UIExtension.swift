//
//  UIExtension.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/13/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import Foundation
import UIKit

extension UIView {

    static func animationItem(duration: TimeInterval, animation: @escaping () -> Void) -> (duration: TimeInterval, animation: () -> Void) {
        return (duration, animation)
    }

    static func executeAnimationSequence(_ animations: [(duration: TimeInterval, animation: () -> Void)]) {
        guard let duration = animations.first?.duration, let animationBlock = animations.first?.animation else {
            return
        }

        UIView.animate(withDuration: duration,
                       animations: animationBlock) { _ in
                        self.executeAnimationSequence(Array(animations.suffix(from: 1)))
        }
    }

}
