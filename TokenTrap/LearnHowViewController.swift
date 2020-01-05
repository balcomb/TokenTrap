//
//  LearnHowViewController.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 10/27/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

typealias TokenGroup = (token1: UIView, token2: UIView, captionLabel: UILabel)

class LearnHowViewController: UIViewController {

    let margin = CGFloat(22)
    let tokenSize = CGFloat(44)
    let tokenPadding = CGFloat(5)

    lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.setTitle("Close", for: .normal)
        closeButton.addTarget(self,
                              action: #selector(handleCloseTap),
                              for: .touchUpInside)
        return closeButton
    }()

    lazy var closeBar: UIView = {
        let closeBar = UIView()
        closeBar.backgroundColor = UIColor(white: 1, alpha: 0.25)
        return closeBar
    }()

    lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        return scrollView
    }()

    lazy var headlineLabel: UILabel = {
        let headlineLabel = self.defaultLabel(text: "TokenTrap is a challenging action-\u{2060}puzzle game requiring logical thinking under pressure")
        headlineLabel.textColor = .gold
        headlineLabel.font = .boldSystemFont(ofSize: 22)
        return headlineLabel
    }()

    lazy var subheadLabel1 = defaultLabel(text: "1. Tokens Have an Icon and a Color")
    lazy var bodyLabel1 = bodyLabel(text: "There are three different icons and three different colors.")

    lazy var tokenGrid = tokenList([(.blue, .die),
                                    (.gray, .die),
                                    (.red, .die),
                                    (.blue, .face),
                                    (.gray, .face),
                                    (.red, .face),
                                    (.blue, .star),
                                    (.gray, .star),
                                    (.red, .star)])

    lazy var subheadLabel2 = defaultLabel(text: "2. Change the Board by Finding Partial Matches")
    lazy var bodyLabel2_1 = bodyLabel(text: "Tokens are partial matches when they have the same icon or the same color (but not both).")
    lazy var tokenGroup2_1 = tokenGroup([(.gray, .face),
                                         (.gray, .star)],
                                        caption: "Partial Match: Color")
    lazy var tokenGroup2_2 = tokenGroup([(.blue, .die),
                                         (.red, .die)],
                                        caption: "Partial Match: Icon")
    lazy var bodyLabel2_2 = bodyLabel(text: "Select a side-by-side pair of tokens that is a partial match, and it becomes a full match. The full match is made by changing the property in which the tokens don't match. For example, if the tokens have the same icon but different colors, each token's color will change to a new matching color.")
    lazy var tokenGroup2_3 = tokenGroup([(.red, .star),
                                         (.gray, .star)],
                                        caption: "Selected Partial Match")
    lazy var tokenGroup2_4 = tokenGroup([(.blue, .star),
                                         (.blue, .star)],
                                        caption: "Resulting Full Match")

    lazy var subheadLabel3 = defaultLabel(text: "3. Clear Rows")
    lazy var bodyLabel3 = bodyLabel(text: "Each level has a target token. Create full match pairs that also match the target, and that pair's row is removed from the board.")

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .background
        addViews()
        addConstraints()
    }

    func addViews() {
        view.addNoMaskSubviews([closeBar,
                                scrollView])
        closeBar.addNoMaskSubviews([closeButton])
        scrollView.addNoMaskSubviews([headlineLabel,
                                      subheadLabel1,
                                      bodyLabel1,
                                      subheadLabel2,
                                      bodyLabel2_1,
                                      bodyLabel2_2,
                                      subheadLabel3,
                                      bodyLabel3])
        scrollView.addNoMaskSubviews(tokenGrid)
        addTokenGroupViews([tokenGroup2_1,
                            tokenGroup2_2,
                            tokenGroup2_3,
                            tokenGroup2_4])
    }

    func addConstraints() {
        let closeHeight = CGFloat(44)

        var constraints = [closeBar.leftAnchor.constraint(equalTo: view.leftAnchor),
                           closeBar.rightAnchor.constraint(equalTo: view.rightAnchor),
                           closeBar.topAnchor.constraint(equalTo: view.topAnchor),
                           closeBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                            constant: closeHeight),

                           closeButton.heightAnchor.constraint(equalToConstant: closeHeight),
                           closeButton.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor,
                                                             constant: margin),
                           closeButton.bottomAnchor.constraint(equalTo: closeBar.bottomAnchor),

                           scrollView.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor),
                           scrollView.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor),
                           scrollView.topAnchor.constraint(equalTo: closeBar.bottomAnchor),
                           scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)]

        constraints.append(contentsOf: labelConstraints(label: headlineLabel,
                                                        topAnchor: scrollView.topAnchor))
        constraints.append(contentsOf: labelConstraints(label: subheadLabel1,
                                                        topAnchor: headlineLabel.bottomAnchor))
        constraints.append(contentsOf: labelConstraints(label: bodyLabel1,
                                                        topAnchor: subheadLabel1.bottomAnchor,
                                                        isBody: true))
        constraints.append(contentsOf: tokenListConstraints(tokens: tokenGrid,
                                                            topAnchor: bodyLabel1.bottomAnchor,
                                                            leftAnchor: headlineLabel.leftAnchor))
        constraints.append(contentsOf: labelConstraints(label: subheadLabel2,
                                                        topAnchor: tokenGrid.last!.bottomAnchor))
        constraints.append(contentsOf: labelConstraints(label: bodyLabel2_1,
                                                        topAnchor: subheadLabel2.bottomAnchor,
                                                        isBody: true))
        constraints.append(contentsOf: tokenGroupConstraints(tokenGroup: tokenGroup2_1,
                                                             topAnchor: bodyLabel2_1.bottomAnchor,
                                                             leftAnchor: headlineLabel.leftAnchor))
        constraints.append(contentsOf: tokenGroupConstraints(tokenGroup: tokenGroup2_2,
                                                             topAnchor: bodyLabel2_1.bottomAnchor,
                                                             leftAnchor: tokenGroup2_1.captionLabel.rightAnchor))
        constraints.append(contentsOf: labelConstraints(label: bodyLabel2_2,
                                                        topAnchor: tokenGroup2_1.captionLabel.bottomAnchor,
                                                        isBody: true))
        constraints.append(contentsOf: tokenGroupConstraints(tokenGroup: tokenGroup2_3,
                                                             topAnchor: bodyLabel2_2.bottomAnchor,
                                                             leftAnchor: headlineLabel.leftAnchor))
        constraints.append(contentsOf: tokenGroupConstraints(tokenGroup: tokenGroup2_4,
                                                             topAnchor: bodyLabel2_2.bottomAnchor,
                                                             leftAnchor: tokenGroup2_3.captionLabel.rightAnchor))
        constraints.append(contentsOf: labelConstraints(label: subheadLabel3,
                                                        topAnchor: tokenGroup2_4.captionLabel.bottomAnchor))
        constraints.append(contentsOf: labelConstraints(label: bodyLabel3,
                                                        topAnchor: subheadLabel3.bottomAnchor,
                                                        isBody: true))
        constraints.forEach { constraint in
            constraint.isActive = true
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        DispatchQueue.main.async {
            self.scrollView.contentSize = CGSize(width: self.scrollView.frame.size.width,
                                                 height: self.bodyLabel3.frame.maxY + self.tokenSize);
        }
    }

    func tokenListConstraints(tokens: [UIView],
                              topAnchor: NSLayoutYAxisAnchor,
                              leftAnchor: NSLayoutXAxisAnchor) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        let rowLength = 3
        let tokenSizePadded = tokenSize + tokenPadding

        for (index, token) in tokens.enumerated() {
            let tokenConstraints = [token.topAnchor.constraint(equalTo: topAnchor,
                                                               constant: (margin / 2) + (tokenSizePadded * CGFloat(index / rowLength))),
                                    token.leftAnchor.constraint(equalTo: leftAnchor,
                                                                constant: margin + (tokenSizePadded * CGFloat(index % rowLength))),
                                    token.widthAnchor.constraint(equalToConstant: tokenSize),
                                    token.heightAnchor.constraint(equalToConstant: tokenSize)]

            constraints.append(contentsOf: tokenConstraints)
        }

        return constraints
    }

    func tokenGroupConstraints(tokenGroup: TokenGroup,
                               topAnchor: NSLayoutYAxisAnchor,
                               leftAnchor: NSLayoutXAxisAnchor) -> [NSLayoutConstraint] {
        var constraints = tokenListConstraints(tokens: [tokenGroup.token1, tokenGroup.token2],
                                               topAnchor: topAnchor,
                                               leftAnchor: leftAnchor)
        let captionConstraints = [tokenGroup.captionLabel.topAnchor.constraint(equalTo: tokenGroup.token1.bottomAnchor,
                                                                               constant: tokenPadding),
                                  tokenGroup.captionLabel.leftAnchor.constraint(equalTo: tokenGroup.token1.leftAnchor),
                                  tokenGroup.captionLabel.rightAnchor.constraint(equalTo: tokenGroup.token2.rightAnchor)]
        constraints.append(contentsOf: captionConstraints)

        return constraints
    }

    func labelConstraints(label: UILabel,
                          topAnchor: NSLayoutYAxisAnchor,
                          isBody: Bool = false) -> [NSLayoutConstraint] {
        let labelWidthConstant = -(margin * 2)
        let topMargin = isBody ? margin / 2 : margin

        return [label.topAnchor.constraint(equalTo: topAnchor,
                                           constant: topMargin),
                label.leftAnchor.constraint(equalTo: scrollView.leftAnchor,
                                            constant: margin),
                label.widthAnchor.constraint(equalTo: scrollView.widthAnchor,
                                             constant: labelWidthConstant)]
    }

    func defaultLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = .boldSystemFont(ofSize: 18)
        label.numberOfLines = 0

        return label
    }

    func bodyLabel(text: String) -> UILabel {
        let label = defaultLabel(text: text)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        label.font = .boldSystemFont(ofSize: 16)

        return label
    }

    func tokenList(_ tokenAttributes: [TokenAttributes]) -> [UIView] {
        var tokens = [UIView]()

        for attributes in tokenAttributes {
            tokens.append(TokenView(attributes))
        }

        return tokens
    }

    func tokenGroup(_ tokenAttributes: [TokenAttributes], caption: String) -> TokenGroup {
        let tokens = tokenList(tokenAttributes)
        let captionLabel = defaultLabel(text: caption)
        captionLabel.font = .boldSystemFont(ofSize: 12)
        captionLabel.textAlignment = .center

        return (tokens[0], tokens[1], captionLabel)
    }

    func addTokenGroupViews(_ tokenGroups: [TokenGroup]) {
        for group in tokenGroups {
            scrollView.addNoMaskSubviews([group.token1,
                                          group.token2,
                                          group.captionLabel])
        }
    }

    @objc func handleCloseTap() {
        dismiss(animated: true, completion: nil)
    }

}
