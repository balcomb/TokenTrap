//
//  MenuView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/12/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import Foundation
import UIKit

class PlayButton: UIButton {
    static let height = CGFloat(44)

    convenience init(title: String) {
        self.init()
        backgroundColor = .buttonBlue
        setTitle(title, for: .normal)
        titleLabel?.font = .boldSystemFont(ofSize: ceil(Self.baseFontSize * 1.2))
        layer.cornerRadius = Self.buttonCornerRadius
    }
}

class MenuView: UIView {

    unowned var viewController: MenuViewController
    var viewConstraints = ViewConstraints()

    lazy var controlConstraints = [logo.topAnchor.constraint(equalTo: topAnchor),
                                   logo.leftAnchor.constraint(equalTo: leftAnchor),

                                   playButton.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: PlayButton.height / 2),
                                   playButton.centerXAnchor.constraint(equalTo: logo.centerXAnchor),
                                   playButton.heightAnchor.constraint(equalToConstant: PlayButton.height),
                                   playButton.widthAnchor.constraint(equalTo: logo.widthAnchor),

                                   skillLabel.topAnchor.constraint(equalTo: playButton.bottomAnchor, constant: skillLabel.font.pointSize),
                                   skillLabel.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),

                                   skillControl.topAnchor.constraint(equalTo: skillLabel.bottomAnchor, constant: skillLabel.font.pointSize / 2),
                                   skillControl.centerXAnchor.constraint(equalTo: skillLabel.centerXAnchor),

                                   learnButton.topAnchor.constraint(equalTo: skillControl.bottomAnchor, constant: skillLabel.font.pointSize * 2),
                                   learnButton.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
                                   learnButton.widthAnchor.constraint(equalTo: playButton.widthAnchor),

                                   trainButton.topAnchor.constraint(equalTo: learnButton.bottomAnchor, constant: skillLabel.font.pointSize / 2),
                                   trainButton.centerXAnchor.constraint(equalTo: playButton.centerXAnchor),
                                   trainButton.widthAnchor.constraint(equalTo: playButton.widthAnchor),

                                   bottomAnchor.constraint(equalTo: trainButton.bottomAnchor),
                                   widthAnchor.constraint(equalTo: logo.widthAnchor)]

    lazy var logo: UIImageView = {
        let logo = UIImageView(image: UIImage(named: "logo"))
        return logo
    }()

    lazy var playButton: UIButton = {
        let playButton = PlayButton(title: "Play")
        playButton.alpha = 0;
        playButton.addTarget(self,
                             action: #selector(self.handlePlayTap),
                             for: .touchUpInside)
        return playButton
    }()

    lazy var skillLabel: UILabel = {
        let skillLabel = UILabel()
        skillLabel.text = "SKILL LEVEL"
        skillLabel.font = .boldSystemFont(ofSize: floor(Self.baseFontSize * 0.8))
        skillLabel.textColor = UIColor(named: "skillColor")
        skillLabel.alpha = 0;
        return skillLabel
    }()

    lazy var skillControl: UISegmentedControl = {
        let skillControl = UISegmentedControl(items: ["Basic", "Expert"])
        skillControl.selectedSegmentIndex = 0

        if #available(iOS 13.0, *) {
            skillControl.backgroundColor = .buttonBlue
            skillControl.selectedSegmentTintColor = .logoBlue
        } else {
            skillControl.tintColor = .logoBlue
            skillControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white],
                                                for: .selected)
        }

        skillControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white,
                                             NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: Self.baseFontSize)],
                                            for: .normal)
        skillControl.alpha = 0;
        skillControl.addTarget(self,
                               action: #selector(self.handleSkillChange),
                               for: .valueChanged)
        return skillControl
    }()

    lazy var learnButton: UIButton = {
        let learnButton = self.outlineButton(title: "Learn How")
        learnButton.addTarget(self,
                              action: #selector(self.handleLearnTap),
                              for: .touchUpInside)
        return learnButton
    }()

    lazy var trainButton: UIButton = {
        let trainButton = self.outlineButton(title: "Play in Training Mode")
        trainButton.addTarget(self,
                              action: #selector(self.handleTrainTap),
                              for: .touchUpInside)
        return trainButton
    }()

    init(viewController: MenuViewController) {
        self.viewController = viewController
        super.init(frame: CGRect.zero)
        addNoMaskSubviews([logo])
        viewConstraints.update([widthAnchor.constraint(equalTo: logo.widthAnchor),
                                heightAnchor.constraint(equalTo: logo.heightAnchor)])

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .seconds(2)) {
            self.renderControls()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func outlineButton(title: String) -> UIButton {
        let button = UIButton()
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: Self.baseFontSize)
        button.layer.borderColor = UIColor.buttonBlue.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = Self.buttonCornerRadius
        button.alpha = 0

        return button
    }

    func renderControls() {
        let controls = [playButton,
                        skillLabel,
                        skillControl,
                        learnButton,
                        trainButton]
        addNoMaskSubviews(controls)
        viewConstraints.update(controlConstraints)

        let shiftLogo: AnimationItem = (0.5, {
            self.layoutIfNeeded()
        })
        let fadeInControls: AnimationItem = (0.3, {
            controls.forEach { control in
                control.alpha = 1
            }
        })
        UIView.executeAnimationSequence([shiftLogo, fadeInControls])
    }

    @objc func handlePlayTap() {
        viewController.handlePlayTap()
        animateTap(button: playButton)
    }

    @objc func handleLearnTap() {
        viewController.handleLearnTap()
        animateTap(button: learnButton)
    }

    @objc func handleTrainTap() {
        viewController.handleTrainTap()
        animateTap(button: trainButton)
    }

    @objc func handleSkillChange() {
        viewController.skillLevelDidChange(expertModeOn: skillControl.selectedSegmentIndex == 1)
    }

    func animateTap(button: UIButton) {
        let duration = 0.08

        let fadeOut: AnimationItem = (duration, {
            button.alpha = 0.6
        })
        let fadeIn: AnimationItem = (duration, {
            button.alpha = 1
        })
        UIView.executeAnimationSequence([fadeOut, fadeIn])
    }
}
