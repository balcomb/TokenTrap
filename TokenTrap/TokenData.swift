//
//  TokenData.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 4/12/20.
//  Copyright © 2020 Ben Balcomb. All rights reserved.
//

import Foundation

class TokenData: Equatable {
    static func == (lhs: TokenData, rhs: TokenData) -> Bool {
        lhs === rhs
    }

    var attributes: TokenAttributes
    var id = TokenID.notSet

    init(attributes: TokenAttributes) {
        self.attributes = attributes
    }
}

typealias TokenID = Int
extension TokenID {
    static var notSet = -1
    static var counterStart = 0

    mutating func incremented() -> TokenID {
        self += 1
        return self
    }
}

class GameData {
    var level = 0
    var score = 0
    var tokenIDCounter = TokenID.counterStart
    var rows = [[TokenData]]()
    var selectedToken: TokenData?
    var targetAttributes: TokenAttributes = (TokenColor.notSet, TokenIcon.notSet)
    var tDataMap = [TokenID: TokenData]()

    var canAddRow: Bool {
        rows.count < GridView.size
    }

    func nextRow() -> [TokenData] {
        var rowData = [TokenData]()

        for _ in 0 ..< GridView.size {
            let tData = TokenData(attributes: (TokenColor.random(), TokenIcon.random()))
            tData.id = tokenIDCounter.incremented()
            rowData.append(tData)
            tDataMap[tData.id] = tData
        }

        rows.append(rowData)

        return rowData
    }

    func rowIndexForID(_ tokenID: TokenID) -> Int? {
        for (index, row) in rows.enumerated() {
            for tData in row {
                if tData.id == tokenID {
                    return index
                }
            }
        }

        return nil
    }

    func removeRowForMatch(tokenID: TokenID) {
        guard let index = rowIndexForID(tokenID) else {
            // TODO: end game?
            return
        }

        for tData in rows[index] {
            tDataMap.removeValue(forKey: tData.id)
        }

        rows.remove(at: index)
    }

    func processTokenTap(tokenID: TokenID) -> TokenTapResult? {
        guard let currentToken = tDataMap[tokenID] else {
            return nil
        }

        guard let previousToken = selectedToken else {
            selectedToken = currentToken
            return .firstSelection(tokenID: tokenID)
        }

        selectedToken = nil
        let selectedPair = TokenDataPair(tData1: currentToken, tData2: previousToken)

        guard selectedPair.isPartialMatch else {
            return .mismatch(tDataPair: selectedPair)
        }

        return processPartialMatch(tDataPair: selectedPair)
    }

    func processPartialMatch(tDataPair: TokenDataPair) -> TokenTapResult {
        tDataPair.updateAttributesForPartialMatch()
        let relation = getPairRelation(tDataPair)

        switch relation {
        case .adjacent:
            return .partialMatch(tDataPair: tDataPair)
        case .adjacentInRow:
            if tDataPair.tData1.attributes == targetAttributes {
                removeRowForMatch(tokenID: tDataPair.tData1.id)
                return .targetMatch(tDataPair: tDataPair)
            } else {
                return .partialMatch(tDataPair: tDataPair)
            }
        case .notAdjacent:
            return .mismatch(tDataPair: tDataPair)
        }
    }

    func getPairRelation(_ tDataPair: TokenDataPair) -> TokenPairRelation {
        for (index, row) in rows.enumerated() {

            guard let tData1Index = row.firstIndex(of: tDataPair.tData1) else {
                continue
            }

            if let tData2Index = row.firstIndex(of: tDataPair.tData2), abs(tData1Index - tData2Index) == 1 {
                return .adjacentInRow
            }

            for adjacentRow in adjacentRows(at: index) {
                if let tData2Index = adjacentRow.firstIndex(of: tDataPair.tData2), tData1Index == tData2Index {
                    return .adjacent
                }
            }
        }

        return .notAdjacent
    }

    func adjacentRows(at index: Int) -> [[TokenData]] {
        var adjacentRows = [[TokenData]]()

        if index > 0 && rows.count > 0 {
            adjacentRows.append(rows[index - 1])
        }

        if index < rows.count - 1 {
            adjacentRows.append(rows[index + 1])
        }

        return adjacentRows
    }
}

enum TokenPairRelation {
    case adjacent
    case adjacentInRow
    case notAdjacent
}

struct TokenDataPair {
    var tData1: TokenData
    var tData2: TokenData

    var isPartialMatch: Bool {
        tData1.attributes != tData2.attributes
            && (tData1.attributes.color == tData2.attributes.color || tData1.attributes.icon == tData2.attributes.icon)
    }

    func updateAttributesForPartialMatch() {
        guard isPartialMatch else { return }

        if tData1.attributes.color == tData2.attributes.color {
            let pairIcons: Set<TokenIcon> = [tData1.attributes.icon,
                                             tData2.attributes.icon]
            if let newIcon = excludedAttribute(allAttributes: TokenIcon.iconSet(), pairAttributes: pairIcons) {
                tData1.attributes.icon = newIcon
                tData2.attributes.icon = newIcon
            }
        } else

        if tData1.attributes.icon == tData2.attributes.icon {
            let pairColors: Set<TokenColor> = [tData1.attributes.color,
                                               tData2.attributes.color]
            if let newColor = excludedAttribute(allAttributes: TokenColor.colorSet(), pairAttributes: pairColors) {
                tData1.attributes.color = newColor
                tData2.attributes.color = newColor
            }
        }
    }

    func excludedAttribute<Type>(allAttributes: Set<Type>, pairAttributes: Set<Type>) -> Type? {
        allAttributes.subtracting(pairAttributes).first
    }
}

