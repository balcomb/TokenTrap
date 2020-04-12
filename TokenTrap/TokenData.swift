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

    var canAddRow: Bool {
        rows.count < GridView.size
    }

    func tokenDataForID(_ tokenID: TokenID) -> TokenData? {

        for row in rows {
            for tokenData in row {
                if tokenData.id == tokenID {
                    return tokenData
                }
            }
        }

        return nil
    }

    func rowIndexForID(_ tokenID: TokenID) -> Int? {
        for (index, row) in rows.enumerated() {
            for token in row {
                if token.id == tokenID {
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

        rows.remove(at: index)
    }

    func processTokenTap(tokenID: TokenID) -> TokenTapResult? {
        guard let currentToken = tokenDataForID(tokenID) else {
            return nil
        }

        guard let previousToken = selectedToken else {
            selectedToken = currentToken
            return .firstSelection
        }

        selectedToken = nil
        let selectedPair = TokenPair(data1: currentToken, data2: previousToken)

        guard selectedPair.isPartialMatch else {
            return .mismatch(tokens: selectedPair)
        }

        return processPartialMatch(tokens: selectedPair)
    }

    func processPartialMatch(tokens: TokenPair) -> TokenTapResult {
        tokens.updateAttributesForPartialMatch()
        let relation = getPairRelation(tokens)

        switch relation {
        case .adjacent:
            return .partialMatch(tokens: tokens)
        case .adjacentInRow:
            if tokens.data1.attributes == targetAttributes {
                removeRowForMatch(tokenID: tokens.data1.id)
                return .targetMatch(tokens: tokens)
            } else {
                return .partialMatch(tokens: tokens)
            }
        case .notAdjacent:
            return .mismatch(tokens: tokens)
        }
    }

    func getPairRelation(_ tokens: TokenPair) -> TokenPairRelation {
        for (index, row) in rows.enumerated() {

            guard let token1Index = row.firstIndex(of: tokens.data1) else {
                continue
            }

            if let token2Index = row.firstIndex(of: tokens.data2), abs(token1Index - token2Index) == 1 {
                return .adjacentInRow
            }

            for adjacentRow in adjacentRows(at: index) {
                if let token2Index = adjacentRow.firstIndex(of: tokens.data2), token1Index == token2Index {
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

struct TokenPair {
    var data1: TokenData
    var data2: TokenData

    var isPartialMatch: Bool {
        data1.attributes != data2.attributes
            && (data1.attributes.color == data2.attributes.color || data1.attributes.icon == data2.attributes.icon)
    }

    func updateAttributesForPartialMatch() {
        guard isPartialMatch else { return }

        if data1.attributes.color == data2.attributes.color {
            let pairIcons: Set<TokenIcon> = [data1.attributes.icon,
                                             data2.attributes.icon]
            if let newIcon = excludedAttribute(allAttributes: TokenIcon.iconSet(), pairAttributes: pairIcons) {
                data1.attributes.icon = newIcon
                data2.attributes.icon = newIcon
            }
        } else

        if data1.attributes.icon == data2.attributes.icon {
            let pairColors: Set<TokenColor> = [data1.attributes.color,
                                               data2.attributes.color]
            if let newColor = excludedAttribute(allAttributes: TokenColor.colorSet(), pairAttributes: pairColors) {
                data1.attributes.color = newColor
                data2.attributes.color = newColor
            }
        }
    }

    func excludedAttribute<Type>(allAttributes: Set<Type>, pairAttributes: Set<Type>) -> Type? {
        allAttributes.subtracting(pairAttributes).first
    }
}

