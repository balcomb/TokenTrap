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
    var tViews: [TokenView]
    var tViewPrime: TokenView {
        tViews.first!
    }

    init?(rowData: [TokenData], view: GridView) {
        guard rowData.count == Constants.gridSize else {
            return nil
        }

        tViews = [TokenView]()

        for tData in rowData {
            let tView = TokenView(tData.attributes)
            tView.id = tData.id
            tView.isWildcard = tData.isWildcard
            let tapGesture = UITapGestureRecognizer(target: view,
                                                    action: #selector(GridView.handleTokenTap(tap:)))
            tView.addGestureRecognizer(tapGesture)
            tViews.append(tView)
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

    func tokenViewPair(forDataPair tDataPair: TokenDataPair) -> TokenViewPair? {
        guard let tView1 = self[tDataPair.tData1.id],
            let tView2 = self[tDataPair.tData2.id] else {

            handleMissingIDs([tDataPair.tData1.id, tDataPair.tData2.id])
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

    static let padding = CGFloat(2)

    weak var controller: GameViewController?

    lazy var rows = [GridRow]()
    lazy var tViewMap = TokenViewMap()
    lazy var tokenConstraints = [TokenID: TokenConstraints]()

    lazy var tViewContainer: UIView = {
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

        for index in 0 ..< Constants.gridSize * Constants.gridSize {
            let view = UIView()
            view.backgroundColor = gridBackground
            views.append(view)
        }

        return views
    }()

    var containerBackground: UIColor {
        UIColor { traits -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor.white.withAlphaComponent(0.15)
            default:
                return UIColor.white.withAlphaComponent(0.1)
            }
        }
    }

    var gridBackground: UIColor {
        UIColor { traits -> UIColor in
            switch traits.userInterfaceStyle {
            case .dark:
                return UIColor.black.withAlphaComponent(0.4)
            default:
                return UIColor.black.withAlphaComponent(0.15)
            }
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)

        guard subviews.count == 0 else {
            return
        }

        layer.masksToBounds = true
        backgroundColor = containerBackground
        layoutGrid()
        bringSubviewToFront(tViewContainer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        backgroundViews.forEach { $0.layer.cornerRadius = $0.frame.size.height / 2 }
    }

    func layoutGrid() {
        addNoMaskSubviews(backgroundViews)

        for (index, view) in backgroundViews.enumerated() {
            // first view in row anchors to superview left, other views anchor to previous view right
            let anchorForLeft = index % Constants.gridSize == 0 ? leftAnchor : backgroundViews[index - 1].rightAnchor
            // first row anchors to superview top, other views anchor to bottom of view above
            let anchorForTop = index < Constants.gridSize ? topAnchor : backgroundViews[index - Constants.gridSize].bottomAnchor

            var constraints = tokenSizeConstraints(view: view)
            constraints.append(contentsOf: [view.leftAnchor.constraint(equalTo: anchorForLeft,
                                                                       constant: GridView.padding),
                                            view.topAnchor.constraint(equalTo: anchorForTop,
                                                                      constant: GridView.padding)])
            constraints.forEach { $0.isActive = true }
        }
    }

    func tokenSizeConstraints(view: UIView) -> [NSLayoutConstraint] {
        let widthMultiplier = 1.0 / CGFloat(Constants.gridSize)
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
        let viewForYAnchor: UIView = rows.last?.tViewPrime ?? self
        let yAnchor = viewForYAnchor == self ? viewForYAnchor.bottomAnchor : viewForYAnchor.topAnchor

        let constraints = TokenConstraints(xPosition: row.tViewPrime.leftAnchor.constraint(equalTo: rightAnchor),
                                           yPosition: row.tViewPrime.bottomAnchor.constraint(equalTo: yAnchor,
                                                                                             constant: -GridView.padding))

        for (index, tView) in row.tViews.enumerated() {
            constraints.otherConstraints.append(contentsOf: tokenSizeConstraints(view: tView))

            if tView != row.tViewPrime {
                constraints.otherConstraints.append(contentsOf: [tView.topAnchor.constraint(equalTo: row.tViewPrime.topAnchor),
                                                                 tView.leftAnchor.constraint(equalTo: row.tViews[index - 1].rightAnchor,
                                                                                             constant: GridView.padding)])
            }
        }

        constraints.isActive = true
        layoutIfNeeded()

        tokenConstraints[row.tViewPrime.id] = constraints
    }

    func showRow(_ row: GridRow) {
        guard let constraints = tokenConstraints[row.tViewPrime.id] else { return }

        constraints.xPositionConstraint = row.tViewPrime.leftAnchor.constraint(equalTo: leftAnchor,
                                                                               constant: GridView.padding)
        let slideInRow: AnimationItem = (0.3, {
            self.layoutIfNeeded()
        })
        UIView.executeAnimationSequence([slideInRow])
    }

    func hideRow(_ row: GridRow,
                 rowBonus: RowBonus,
                 completion: @escaping () -> Void) {
        guard let constraints = tokenConstraints[row.tViewPrime.id] else { return }

        constraints.xPositionConstraint = row.tViewPrime.leftAnchor.constraint(equalTo: leftAnchor,
                                                                               constant: -frame.size.width)
        let slideOutRow: AnimationItem = (0.3, {
            self.layoutIfNeeded()
        })

        var animations = [slideOutRow]

        let bonusLabel = createBonusLabel(row: row, rowBonus: rowBonus)

        if let bonusLabel = bonusLabel {
            let flashSequence = UIView.flashSequence(views: [bonusLabel])
            animations.append(contentsOf: flashSequence)
        }

        let shiftRowsAbove: AnimationItem = (0.3, {
            bonusLabel?.alpha = 0
            self.shiftRowsAbove(row: row)
        })
        animations.append(shiftRowsAbove)

        UIView.executeAnimationSequence(animations) {
            bonusLabel?.removeFromSuperview()
            completion()
        }
    }

    func createBonusLabel(row: GridRow, rowBonus: RowBonus) -> UILabel? {
        guard rowBonus != .none else {
            return nil
        }

        let label = UILabel()
        label.alpha = 0
        label.font = .systemFont(ofSize: row.tViewPrime.frame.size.height * 0.7,
                                 weight: .heavy)
        label.text = "+" + String(rowBonus.rawValue)
        label.textColor = .targetYellow
        addNoMaskSubviews([label])
        NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     label.centerYAnchor.constraint(equalTo: row.tViewPrime.centerYAnchor)])
        return label
    }

    func shiftRowsAbove(row: GridRow) {
        guard row != rows.last else { return }
        guard let index = rows.firstIndex(of: row) else { return }
        let firstTokenAbove = rows[index + 1].tViewPrime
        guard let aboveConstraints = tokenConstraints[firstTokenAbove.id] else { return }

        // prime token above row being removed anchors to either superview bottom or top of the prime token beneath
        let anchor = index == 0 ? bottomAnchor : rows[index - 1].tViewPrime.topAnchor
        aboveConstraints.yPositionConstraint = firstTokenAbove.bottomAnchor.constraint(equalTo: anchor,
                                                                                       constant: -GridView.padding)
        layoutIfNeeded()
    }

    func rowForID(tokenID: TokenID) -> GridRow? {
        guard let tView = tViewMap.tokenView(forID: tokenID) else { return nil }

        for row in rows {
            if row.tViews.contains(tView) {
                return row
            }
        }

        return nil
    }

    @objc func handleTokenTap(tap: UITapGestureRecognizer) {
        guard let tView = tap.view as? TokenView else { return }
        controller?.tokenTapped(tokenID: tView.id)
    }

    func processTokenTapResult(_ result: TokenTapResult) {

        switch result {
        case .firstSelection(let tokenID):
            updateForFirstSelection(tokenID: tokenID)
        case .mismatch(let tDataPair):
            updateForMismatch(tDataPair)
        case .partialMatch(let tDataPair):
            updateForPartialMatch(tDataPair)
        case .targetMatch(let tDataPair, _, let rowBonus):
            updateForTargetMatch(tDataPair, rowBonus: rowBonus)
        }
    }

    func updateForFirstSelection(tokenID: TokenID) {
        tViewMap.tokenView(forID: tokenID)?.highlight = .selected
    }

    func updateForMismatch(_ tDataPair: TokenDataPair) {
        guard let tViewPair = tViewMap.tokenViewPair(forDataPair: tDataPair) else { return }

        tViewPair.updateHighlight(.mismatch)

        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(300)) {
            tViewPair.updateHighlight(.normal)
        }
    }

    func updateForPartialMatch(_ tDataPair: TokenDataPair) {
        tViewMap.tokenViewPair(forDataPair: tDataPair)?.update(withData: tDataPair.tData1)
    }

    func updateForTargetMatch(_ tDataPair: TokenDataPair, rowBonus: RowBonus) {
        tViewMap.tokenViewPair(forDataPair: tDataPair)?.update(withData: tDataPair.tData1,
                                                               highlight: .targetMatch) {
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + .milliseconds(300)) {
                self.removeRow(tokenID: tDataPair.tData1.id, rowBonus: rowBonus)
            }
        }
    }

    func removeRow(tokenID: TokenID, rowBonus: RowBonus) {
        guard let row = rowForID(tokenID: tokenID) else { return }

        hideRow(row, rowBonus: rowBonus) {
            self.cleanUpHiddenRow(row)
        }
    }

    func cleanUpHiddenRow(_ row: GridRow) {
        row.tViews.forEach {
            $0.removeFromSuperview()
            tViewMap.removeValue(forKey: $0.id)
        }
        rows.removeAll { $0 == row }
        tokenConstraints.removeValue(forKey: row.tViewPrime.id)?.isActive = false
    }

    func addRow(_ rowData: [TokenData]) {
        guard let row = GridRow(rowData: rowData, view: self) else { return }

        row.tViews.forEach { tViewMap[$0.id] = $0 }
        tViewContainer.addNoMaskSubviews(row.tViews)
        setUpRowConstraints(row)
        rows.append(row)
        showRow(row)
    }

    func blockTokenTaps() {
        for row in rows {
            row.tViews.forEach { $0.isUserInteractionEnabled = false }
        }
    }

    func clearGrid() {
        var views = backgroundViews
        rows.forEach {
            views.append(contentsOf: $0.tViews)
        }

        fade(alpha: 0, views: views) {
            self.rows.forEach { self.cleanUpHiddenRow($0) }
            self.rows.removeAll()
        }
    }

    func showBackground() {
        fade(alpha: 1,
             views: backgroundViews)
    }

    func fade(alpha: CGFloat, views: [UIView], completion: (() -> Void)? = nil) {
        let fade: AnimationItem = (0.3, {
            views.forEach { $0.alpha = alpha }
        })
        UIView.executeAnimationSequence([fade]) {
            completion?()
        }
    }

    func updateForMenuState(isShowing: Bool) {
        tViewContainer.isHidden = isShowing
    }

    func activateTrainingHelpers(tokenIDs: [TokenID]) {
        tokenIDs.forEach {
            self.tViewMap[$0]?.highlight = .trainingHelper
        }
    }
}
