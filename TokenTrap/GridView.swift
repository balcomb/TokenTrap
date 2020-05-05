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
        guard data.count == GridView.size else {
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

struct TokenViewPair {
    var tViews: (TokenView, TokenView)

    func updateHighlight(_ highlight: TokenHighlight) {
        tViews.0.highlight = highlight
        tViews.1.highlight = highlight
    }

    func update(withData data: TokenData,
                highlight: TokenHighlight = .normal,
                completion: (() -> Void)? = nil) {
        tViews.0.update(withData: data,
                        highlight: highlight)
        tViews.1.update(withData: data,
                        highlight: highlight,
                        completion: completion)
    }
}

typealias TokenViewMap = [TokenID: TokenView]
extension TokenViewMap {

    func tokenView(forID id: TokenID) -> TokenView? {
        guard let tView = self[id] else {
            handleMissingIDs([id])
            return nil
        }

        return tView
    }

    func tokenViewPair(forDataPair tDataPair: TokenPair) -> TokenViewPair? {
        guard let tView1 = self[tDataPair.data1.id],
            let tView2 = self[tDataPair.data2.id] else {

            handleMissingIDs([tDataPair.data1.id, tDataPair.data2.id])
            return nil
        }

        return TokenViewPair(tViews: (tView1, tView2))
    }

    func handleMissingIDs(_ tokenIDs: [TokenID]) {
        print("TokenID errer: " + tokenIDs.debugDescription)
        // TODO: end game?
    }
}

class GridView: UIView {

    static let size = 8
    static let padding = CGFloat(2)

    weak var controller: GameViewController?

    lazy var rows = [GridRow]()
    lazy var tViewMap = TokenViewMap()
    lazy var tokenConstraints = [TokenID: TokenConstraints]()

    lazy var tokenContainer: UIView = {
        let container = UIView()
        addNoMaskSubviews([container])
        let constraints = [container.widthAnchor.constraint(equalTo: widthAnchor),
                           container.heightAnchor.constraint(equalTo: heightAnchor),
                           container.centerXAnchor.constraint(equalTo: centerXAnchor),
                           container.centerYAnchor.constraint(equalTo: centerYAnchor)]
        constraints.forEach { $0.isActive = true }
        return container
    }()

    lazy var backgroundViews: [UIView] = {
        var views = [UIView]()

        for index in 0 ..< GridView.size * GridView.size {
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
        bringSubviewToFront(tokenContainer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundViews.forEach { $0.layer.cornerRadius = $0.frame.size.height / 2 }
    }

    func layoutGrid() {
        addNoMaskSubviews(backgroundViews)

        for (index, view) in backgroundViews.enumerated() {
            // first view in row anchors to superview left, other views anchor to previous view right
            let anchorForLeft = index % GridView.size == 0 ? leftAnchor : backgroundViews[index - 1].rightAnchor
            // first row anchors to superview top, other views anchor to bottom of view above
            let anchorForTop = index < GridView.size ? topAnchor : backgroundViews[index - GridView.size].bottomAnchor

            var constraints = tokenSizeConstraints(view: view)
            constraints.append(contentsOf: [view.leftAnchor.constraint(equalTo: anchorForLeft,
                                                                       constant: GridView.padding),
                                            view.topAnchor.constraint(equalTo: anchorForTop,
                                                                      constant: GridView.padding)])
            constraints.forEach { $0.isActive = true }
        }
    }

    func tokenSizeConstraints(view: UIView) -> [NSLayoutConstraint] {
        let widthMultiplier = 1.0 / CGFloat(GridView.size)
        let widthConstant = -(GridView.padding + (GridView.padding * widthMultiplier))

        return [view.widthAnchor.constraint(equalTo: widthAnchor,
                                            multiplier: widthMultiplier,
                                            constant: widthConstant),
                view.heightAnchor.constraint(equalTo: view.widthAnchor)]
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
                                                                                             constant: -GridView.padding))

        for (index, token) in row.tokens.enumerated() {
            constraints.otherConstraints.append(contentsOf: tokenSizeConstraints(view: token))

            if token != row.primeToken {
                constraints.otherConstraints.append(contentsOf: [token.topAnchor.constraint(equalTo: row.primeToken.topAnchor),
                                                                 token.leftAnchor.constraint(equalTo: row.tokens[index - 1].rightAnchor,
                                                                                             constant: GridView.padding)])
            }
        }

        constraints.isActive = true
        layoutIfNeeded()

        tokenConstraints[row.primeToken.id] = constraints
    }

    func showRow(_ row: GridRow) {
        guard let constraints = tokenConstraints[row.primeToken.id] else { return }

        constraints.xPositionConstraint = row.primeToken.leftAnchor.constraint(equalTo: leftAnchor,
                                                                               constant: GridView.padding)
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
                                                                                       constant: -GridView.padding)
        layoutIfNeeded()
    }

    func rowForID(tokenID: TokenID) -> GridRow? {
        guard let tView = tViewMap.tokenView(forID: tokenID) else { return nil }

        for row in rows {
            if row.tokens.contains(tView) {
                return row
            }
        }

        return nil
    }

    @objc func handleTokenTap(tap: UITapGestureRecognizer) {
        guard let token = tap.view as? TokenView else { return }
        controller?.tokenTapped(tokenID: token.id)
    }

    func updateForFirstSelection(tokenID: TokenID) {
        tViewMap.tokenView(forID: tokenID)?.highlight = .selected
    }

    func updateForMismatch(_ pairData: TokenPair) {
        guard let tViewPair = tViewMap.tokenViewPair(forDataPair: pairData) else { return }

        tViewPair.updateHighlight(.mismatch)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(300)) {
            tViewPair.updateHighlight(.normal)
        }
    }

    func updateForPartialMatch(_ pairData: TokenPair) {
        tViewMap.tokenViewPair(forDataPair: pairData)?.update(withData: pairData.data1)
    }

    func updateForTargetMatch(_ pairData: TokenPair) {
        tViewMap.tokenViewPair(forDataPair: pairData)?.update(withData: pairData.data1,
                                                              highlight: .targetMatch) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(300)) {
                self.removeRow(tokenID: pairData.data1.id)
            }
        }
    }

    func removeRow(tokenID: TokenID) {
        guard let row = rowForID(tokenID: tokenID) else { return }

        hideRow(row) {
            self.cleanUpHiddenRow(row)
        }
    }

    func cleanUpHiddenRow(_ row: GridRow) {
        row.tokens.forEach {
            $0.removeFromSuperview()
            tViewMap.removeValue(forKey: $0.id)
        }
        rows.removeAll { $0 == row }
        tokenConstraints.removeValue(forKey: row.primeToken.id)?.isActive = false
    }

    func addRow(_ data: [TokenData]) {
        guard let row = GridRow(data: data, view: self) else { return }

        row.tokens.forEach { tViewMap[$0.id] = $0 }
        tokenContainer.addNoMaskSubviews(row.tokens)
        setUpRowConstraints(row)
        rows.append(row)
        showRow(row)
    }

    func blockTokenTaps() {
        for row in rows {
            row.tokens.forEach { $0.isUserInteractionEnabled = false }
        }
    }

    func clearGrid() {
        var views = backgroundViews
        rows.forEach {
            views.append(contentsOf: $0.tokens)
        }

        let fadeViews: AnimationItem = (0.3, {
            views.forEach { $0.alpha = 0 }
        })
        UIView.executeAnimationSequence([fadeViews]) {
            self.rows.forEach { self.cleanUpHiddenRow($0) }
            self.rows.removeAll()
        }
    }

    func updateForMenuState(isShowing: Bool) {
        tokenContainer.isHidden = isShowing
    }
}
