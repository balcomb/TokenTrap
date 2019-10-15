//
//  MenuView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/12/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import Foundation
import UIKit

class MenuView: UIView {

    var viewController: MenuViewController

    let playButtonHeight = CGFloat(44)
    let baseFontSize = CGFloat(15)
    let buttonCornerRadius = CGFloat(4)
    let buttonBlue = UIColor(named: "buttonBlue")

    var subviewConstraints = [NSLayoutConstraint]()

    lazy var logo: UIImageView = {
        let logo = UIImageView(image: UIImage(named: "logo"))
        logo.translatesAutoresizingMaskIntoConstraints = false
        return logo
    }()

    lazy var playButton: UIButton = {
        let playButton = UIButton()
        playButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.backgroundColor = self.buttonBlue
        playButton.setTitle("Play", for: .normal)
        playButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: ceil(self.baseFontSize * 1.2))
        playButton.layer.cornerRadius = self.buttonCornerRadius
        playButton.alpha = 0;
        playButton.addTarget(self,
                             action: #selector(self.handlePlayTap(button:)),
                             for: .touchUpInside)
        return playButton
    }()

    lazy var skillLabel: UILabel = {
        let skillLabel = UILabel()
        skillLabel.translatesAutoresizingMaskIntoConstraints = false
        skillLabel.text = "SKILL LEVEL"
        skillLabel.font = UIFont.boldSystemFont(ofSize: floor(self.baseFontSize * 0.8))
        skillLabel.textColor = UIColor(named: "skillColor")
        skillLabel.alpha = 0;
        return skillLabel
    }()

    lazy var skillControl: UISegmentedControl = {
        let skillControl = UISegmentedControl(items: ["Basic", "Expert"])
        skillControl.translatesAutoresizingMaskIntoConstraints = false
        skillControl.selectedSegmentIndex = 0
        let tintColor = UIColor(named: "logoBlue")

        if #available(iOS 13.0, *) {
            skillControl.backgroundColor = self.buttonBlue
            skillControl.selectedSegmentTintColor = tintColor
        } else {
            skillControl.tintColor = tintColor
            skillControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white],
                                                for: .selected)
        }

        skillControl.setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.white,
                                             NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: self.baseFontSize)],
                                            for: .normal)
        skillControl.alpha = 0;
        skillControl.addTarget(self,
                               action: #selector(self.handleSkillChange(control:)),
                               for: .valueChanged)
        return skillControl
    }()

    lazy var learnButton: UIButton = {
        let learnButton = self.outlineButton(title: "Learn How")
        learnButton.addTarget(self,
                              action: #selector(self.handleLearnTap(button:)),
                              for: .touchUpInside)
        return learnButton
    }()

    lazy var trainButton: UIButton = {
        let trainButton = self.outlineButton(title: "Play in Training Mode")
        trainButton.addTarget(self,
                              action: #selector(self.handleTrainTap(button:)),
                              for: .touchUpInside)
        return trainButton
    }()

    init(viewController: MenuViewController) {
        self.viewController = viewController
        super.init(frame: CGRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(logo)
        addLayoutConstraints([widthAnchor.constraint(equalTo: logo.widthAnchor),
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
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: baseFontSize)
        button.layer.borderWidth = 1
        button.layer.cornerRadius = self.buttonCornerRadius
        button.alpha = 0

        return button
    }

    override func layoutSubviews() {
        learnButton.layer.borderColor = self.buttonBlue?.cgColor
        trainButton.layer.borderColor = self.buttonBlue?.cgColor
    }

    func renderControls() {
        let controls = [playButton, skillLabel, skillControl, learnButton, trainButton]

        controls.forEach { control in
            addSubview(control)
        }

        addLayoutConstraints([logo.topAnchor.constraint(equalTo: topAnchor),
                              logo.leftAnchor.constraint(equalTo: leftAnchor),

                              playButton.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: playButtonHeight / 2),
                              playButton.centerXAnchor.constraint(equalTo: logo.centerXAnchor),
                              playButton.heightAnchor.constraint(equalToConstant: playButtonHeight),
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
                              widthAnchor.constraint(equalTo: logo.widthAnchor)])

        let shiftLogo = UIView.animationItem(duration: 0.5) {
            self.layoutIfNeeded()
        }
        let fadeInControls = UIView.animationItem(duration: 0.3) {
            controls.forEach { control in
                control.alpha = 1
            }
        }
        UIView.executeAnimationSequence([shiftLogo, fadeInControls])
    }

    func addLayoutConstraints(_ constraints: [NSLayoutConstraint]) {
        subviewConstraints.forEach { constraint in
            constraint.isActive = false
        }
        subviewConstraints = constraints
        subviewConstraints.forEach { constraint in
            constraint.isActive = true
        }
    }

    @objc func handlePlayTap(button: UIButton) {
        viewController.handlePlayTap()
        animateTap(button: button)
    }

    @objc func handleLearnTap(button: UIButton) {
        viewController.handleLearnTap()
        animateTap(button: button)
    }

    @objc func handleTrainTap(button: UIButton) {
        viewController.handleTrainTap()
        animateTap(button: button)
    }

    @objc func handleSkillChange(control: UISegmentedControl) {
        viewController.isExpertMode = control.selectedSegmentIndex == 1
    }

    func animateTap(button: UIButton) {
        let duration = 0.08

        let fadeOut = UIView.animationItem(duration: duration) {
            button.alpha = 0.6
        }
        let fadeIn = UIView.animationItem(duration: duration) {
            button.alpha = 1
        }
        UIView.executeAnimationSequence([fadeOut, fadeIn])
    }
}
