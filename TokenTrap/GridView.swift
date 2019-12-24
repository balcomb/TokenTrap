//
//  GridView.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 12/19/19.
//  Copyright © 2019 Ben Balcomb. All rights reserved.
//

import UIKit

class TokenConstraints {
    var xPositionConstraint: NSLayoutConstraint {
        willSet {
            updatePosition(oldConstraint: xPositionConstraint,
                           newConstraint: newValue)
        }
    }
    var yPositionConstraint: NSLayoutConstraint {
        willSet {
            updatePosition(oldConstraint: yPositionConstraint,
                           newConstraint: newValue)
        }
    }

    lazy var otherConstraints = [NSLayoutConstraint]()

    var isActive = false {
        didSet {
            xPositionConstraint.isActive = isActive
            yPositionConstraint.isActive = isActive
            otherConstraints.forEach { $0.isActive = isActive }
        }
    }

    init(xPosition: NSLayoutConstraint, yPosition: NSLayoutConstraint) {
        xPositionConstraint = xPosition
        yPositionConstraint = yPosition
    }

    func updatePosition(oldConstraint: NSLayoutConstraint,
                        newConstraint: NSLayoutConstraint) {
        oldConstraint.isActive = false
        newConstraint.isActive = true
    }
}

class GridRow: Equatable {
    var tokens: [TokenView]
    var primeToken: TokenView {
        tokens.first!
    }

    init?(data: [TokenData], view: GridView) {
        guard data.count == view.gridSize else {
            return nil
        }

        tokens = [TokenView]()

        for tokenData in data {
            let token = TokenView(tokenData.attributes)
            token.id = tokenData.id
            let tapGesture = UITapGestureRecognizer(target: view,
                                                    action: #selector(GridView.handleTokenTap(tap:)))
            token.addGestureRecognizer(tapGesture)
            tokens.append(token)
        }
    }

    static func == (lhs: GridRow, rhs: GridRow) -> Bool {
        lhs === rhs
    }
}

typealias GridSize = Int
extension GridSize {
    static var standard = 8
}

class GridView: UIView {

    weak var controller: GameViewController?

    let gridSize = GridSize.standard
    let gridPadding = CGFloat(2)

    lazy var rows = [GridRow]()
    lazy var tokenConstraints = [TokenID: TokenConstraints]()

    lazy var widthMultiplier: CGFloat = {
        1.0 / CGFloat(gridSize)
    }()
    lazy var widthConstant: CGFloat = {
        -(gridPadding + (gridPadding * widthMultiplier))
    }()

    lazy var backgroundViews: [UIView] = {
        var views = [UIView]()

        for index in 0 ..< gridSize * gridSize {
            let view = UIView()
            view.backgroundColor = UIColor.black.withAlphaComponent(0.15)
            views.append(view)
        }

        return views
    }()

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        guard subviews.count == 0 else {
            return
        }

        layer.masksToBounds = true
        backgroundColor = UIColor.white.withAlphaComponent(0.1)
        layoutGrid()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundViews.forEach { $0.layer.cornerRadius = $0.frame.size.height / 2 }
    }

    func layoutGrid() {
        addNoMaskSubviews(backgroundViews)

        for (index, view) in backgroundViews.enumerated() {
            // first view in row anchors to superview left, other views anchor to previous view right
            let anchorForLeft = index % gridSize == 0 ? leftAnchor : backgroundViews[index - 1].rightAnchor
            // first row anchors to superview top, other views anchor to bottom of view above
            let anchorForTop = index < gridSize ? topAnchor : backgroundViews[index - gridSize].bottomAnchor

            var constraints = tokenSizeConstraints(view: view)
            constraints.append(contentsOf: [view.leftAnchor.constraint(equalTo: anchorForLeft,
                                                                       constant: gridPadding),
                                            view.topAnchor.constraint(equalTo: anchorForTop,
                                                                      constant: gridPadding)])
            constraints.forEach { $0.isActive = true }
        }
    }

    func tokenSizeConstraints(view: UIView) -> [NSLayoutConstraint] {
        [view.widthAnchor.constraint(equalTo: widthAnchor,
                                     multiplier: widthMultiplier,
                                     constant: widthConstant),
         view.heightAnchor.constraint(equalTo: view.widthAnchor)]
    }

    @objc func handleTokenTap(tap: UITapGestureRecognizer) {
        guard let token = tap.view as? TokenView else { return }
        controller?.tokenTapped(tokenView: token)
    }

    func setUpRowConstraints(_ row: GridRow) {
        /**
         * The prime token anchors to superview right before animating, and either
         * superview bottom or the top of the prime token beneath it.
         * This method must be called before a new row is added to rows.
         */
        let viewForYAnchor: UIView = rows.last?.primeToken ?? self
        let yAnchor = viewForYAnchor == self ? viewForYAnchor.bottomAnchor : viewForYAnchor.topAnchor

        let constraints = TokenConstraints(xPosition: row.primeToken.leftAnchor.constraint(equalTo: rightAnchor),
                                           yPosition: row.primeToken.bottomAnchor.constraint(equalTo: yAnchor,
                                                                                             constant: -gridPadding))

        for (index, token) in row.tokens.enumerated() {
            constraints.otherConstraints.append(contentsOf: tokenSizeConstraints(view: token))

            if token != row.primeToken {
                constraints.otherConstraints.append(contentsOf: [token.topAnchor.constraint(equalTo: row.primeToken.topAnchor),
                                                                 token.leftAnchor.constraint(equalTo: row.tokens[index - 1].rightAnchor,
                                                                                             constant: gridPadding)])
            }
        }

        constraints.isActive = true
        layoutIfNeeded()

        tokenConstraints[row.primeToken.id] = constraints
    }

    func showRow(_ row: GridRow) {
        guard let constraints = tokenConstraints[row.primeToken.id] else { return }

        constraints.xPositionConstraint = row.primeToken.leftAnchor.constraint(equalTo: leftAnchor,
                                                                               constant: gridPadding)
        let slideInRow: AnimationItem = (0.3, {
            self.layoutIfNeeded()
        })
        UIView.executeAnimationSequence([slideInRow])
    }

    func hideRow(_ row: GridRow,
                 completion: @escaping () -> Void) {
        guard let constraints = tokenConstraints[row.primeToken.id] else { return }

        constraints.xPositionConstraint = row.primeToken.leftAnchor.constraint(equalTo: leftAnchor,
                                                                               constant: -frame.size.width)
        let slideOutRow: AnimationItem = (0.3, {
            self.layoutIfNeeded()
        })
        let shiftRowsAbove: AnimationItem = (0.3, {
            self.shiftRowsAbove(row: row)
        })
        UIView.executeAnimationSequence([slideOutRow,
                                         shiftRowsAbove]) {
            completion()
        }
    }

    func shiftRowsAbove(row: GridRow) {
        guard row != rows.last else { return }
        guard let index = rows.firstIndex(of: row) else { return }
        let firstTokenAbove = rows[index + 1].primeToken
        guard let aboveConstraints = tokenConstraints[firstTokenAbove.id] else { return }

        // prime token above row being removed anchors to either superview bottom or top of the prime token beneath
        let anchor = index == 0 ? bottomAnchor : rows[index - 1].primeToken.topAnchor
        aboveConstraints.yPositionConstraint = firstTokenAbove.bottomAnchor.constraint(equalTo: anchor,
                                                                                       constant: -gridPadding)
        layoutIfNeeded()
    }

    func rowForID(tokenID: TokenID) -> GridRow? {
        for row in rows {
            for token in row.tokens {
                if token.id == tokenID {
                    return row
                }
            }
        }

        return nil
    }

    func removeRow(tokenID: TokenID) {
        guard let row = rowForID(tokenID: tokenID) else { return }

        hideRow(row) {
            self.cleanUpHiddenRow(row)
        }
    }

    func cleanUpHiddenRow(_ row: GridRow) {
        row.tokens.forEach { $0.removeFromSuperview() }
        rows.removeAll { $0 == row }
        tokenConstraints.removeValue(forKey: row.primeToken.id)?.isActive = false
    }

    func addRow(data: [TokenData]) {
        guard let row = GridRow(data: data, view: self) else { return }

        addNoMaskSubviews(row.tokens)
        setUpRowConstraints(row)
        rows.append(row)
        showRow(row)
    }
}
