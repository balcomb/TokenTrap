//
//  TokenData.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 4/12/20.
//  Copyright © 2020 Ben Balcomb. All rights reserved.
//

import Foundation

var fiftyFifty: Bool {
    [true, false].randomElement()!
}

class TokenData: Equatable {
    static func == (lhs: TokenData, rhs: TokenData) -> Bool {
        lhs === rhs
    }

    var attributes: TokenAttributes
    var id = TokenID.notSet
    var isWildcard = false
    var isTrainingHelper = false
    var rowBonus = RowBonus.none

    init(attributes: TokenAttributes) {
        self.attributes = attributes
    }

    static func random() -> TokenData {
        TokenData(attributes: (TokenColor.random(), TokenIcon.random()))
    }

    static func randomKeySequence(attributes: TokenAttributes) -> [TokenData] {
        let pair = Self.randomKeyPair(attributes: attributes)
        return [pair.0, pair.1]
    }

    static func randomKeyPair(attributes: TokenAttributes) -> (TokenData, TokenData) {
        let pairAttributes: (TokenAttributes, TokenAttributes)

        if fiftyFifty {
            let colors = TokenColor.colorSet().subtracting([attributes.color]).shuffled()
            pairAttributes = ((colors[0], attributes.icon),
                              (colors[1], attributes.icon))
        } else {
            let icons = TokenIcon.iconSet().subtracting([attributes.icon]).shuffled()
            pairAttributes = ((attributes.color, icons[0]),
                              (attributes.color, icons[1]))
        }

        return (TokenData(attributes: pairAttributes.0),
                TokenData(attributes: pairAttributes.1))
    }
}

typealias TokenDataRow = [TokenData]
extension TokenDataRow {

    var bonus: RowBonus {
        guard let firstTData = first else { return .none }
        return firstTData.rowBonus
    }

    var isChallengeRow: Bool {
        guard let firstTData = first else { return false }
        return firstTData.rowBonus != .none
    }

    func setAllWildcards() {
        forEach { $0.isWildcard = true }
        first?.rowBonus = .wildcard
    }

    func addRandomWildcard() {
        self.randomElement()?.isWildcard = true
    }

    func trainingHelperID() -> TokenID? {
        for tData in self {
            if tData.isTrainingHelper {
                return tData.id
            }
        }

        return nil
    }

    func assignTrainingHelper(_ trainingModeOn: Bool) {
        if trainingModeOn {
            randomElement()?.isTrainingHelper = true
        }
    }

    static func allMatchesRow(targetAttributes: TokenAttributes,
                              trainingModeOn: Bool) -> TokenDataRow {
        let keyPair = TokenData.randomKeyPair(attributes: targetAttributes)
        let keySequence = TokenData.randomKeySequence(attributes: keyPair.0.attributes)
                            + TokenData.randomKeySequence(attributes: keyPair.1.attributes)
        keySequence.assignTrainingHelper(trainingModeOn)

        let randomKeyPair1 = TokenData.randomKeySequence(attributes: TokenData.random().attributes)
        let randomKeyPair2 = TokenData.randomKeySequence(attributes: TokenData.random().attributes)

        let subSequences = [keySequence, randomKeyPair1, randomKeyPair2]

        return TokenDataRow(subSequences.shuffled().joined())
    }

    static func standardRow(targetAttributes: TokenAttributes,
                            trainingModeOn: Bool) -> TokenDataRow {
        var row = TokenDataRow()
        var keySequence = TokenData.randomKeySequence(attributes: targetAttributes)
        keySequence.assignTrainingHelper(trainingModeOn)
        let keyStartIndexUpperBound = Constants.gridSize - keySequence.count + 1
        let keyStartIndex = arc4random_uniform(UInt32(keyStartIndexUpperBound))

        for index in 0 ..< Constants.gridSize {
            let tData = index >= keyStartIndex && !keySequence.isEmpty
                ? keySequence.removeFirst()
                : TokenData.random()
            row.append(tData)
        }

        return row
    }

    static func uniformRow() -> TokenDataRow {
        let firstTData = TokenData.random()
        firstTData.rowBonus = .uniform
        var row = [firstTData]

        while row.count < Constants.gridSize {
            row.append(TokenData(attributes: firstTData.attributes))
        }

        return row
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

class ChallengeLogic {
    /**
     * challenge progression:
     * 1: uniform rows
     * 2: one wildcard per row (+ uniform for expert mode)
     * 3: wildcard rows (+ uniform & one wildcard per row for expert mode)
     * rest of game: both challenge rows plus one wildcard per row
     */

    unowned var gameData: GameData

    init(gameData: GameData) {
        self.gameData = gameData
    }

    var expertModeOn: Bool { gameData.expertModeOn }
    var level: Int { gameData.level }
    var rows: [TokenDataRow] { gameData.rows }

    var challengeStartLevel: Int {
        expertModeOn ? 2 : 5
    }

    var wildcardRowStartLevel: Int {
        challengeStartLevel + 2
    }

    var isUniformRowChallengeLevel: Bool {
        expertModeOn
            ? level >= challengeStartLevel
            : level == challengeStartLevel || level > wildcardRowStartLevel
    }

    var isWildcardRowChallengeLevel: Bool {
        level >= wildcardRowStartLevel
    }

    var isRandomWildcardChallengeLevel: Bool {
        expertModeOn
            ? level > challengeStartLevel
            : level == challengeStartLevel + 1 || level > wildcardRowStartLevel + 1
    }

    var canAddChallengeRow: Bool {
        rows.count > 2
            && rows.allSatisfy({ $0.isChallengeRow == false })
            && fiftyFifty
    }
}

class GameData {

    var level = 0
    var expertModeOn = false
    var trainingModeOn = false
    var score = 0
    var rowsCleared = 0
    var tokenIDCounter = TokenID.counterStart
    var rows = [[TokenData]]()
    var selectedToken: TokenData?
    var targetAttributes: TokenAttributes = (TokenColor.notSet, TokenIcon.notSet)
    var tDataMap = [TokenID: TokenData]()

    lazy var challengeLogic = ChallengeLogic(gameData: self)

    var canAddRow: Bool {
        rows.count < Constants.gridSize
    }

    func levelUp() {
        level += 1
        resetLevel()
    }

    func resetLevel() {
        tDataMap.removeAll()
        rows.removeAll()
        rowsCleared = 0
    }

    func reset() {
        resetLevel()
        level = 0
        score = 0
    }

    func nextRow() -> [TokenData] {
        let rowData = buildRowData()
        rows.append(rowData)
        updateMap(rowData)

        return rowData
    }

    func buildRowData() -> [TokenData] {
        if let uniformRow = buildUniformRow() {
            return uniformRow
        }

        let row: TokenDataRow

        if let allMatchesRow = buildAllMatchesRow() {
            row = allMatchesRow
        } else {
            row = TokenDataRow.standardRow(targetAttributes: targetAttributes,
                                           trainingModeOn: trainingModeOn)
        }

        addWildcards(row)
        return row
    }

    func buildAllMatchesRow() -> TokenDataRow? {
        guard ((expertModeOn || level > 4) && arc4random_uniform(3) == 0)
            || (!expertModeOn && level == 4) else {
            return nil
        }

        return TokenDataRow.allMatchesRow(targetAttributes: targetAttributes,
                                          trainingModeOn: trainingModeOn)
    }

    func buildUniformRow() -> [TokenData]? {
        guard challengeLogic.isUniformRowChallengeLevel
            && challengeLogic.canAddChallengeRow else {
            return nil
        }

        return TokenDataRow.uniformRow()
    }

    func addWildcards(_ row: [TokenData]) {
        if challengeLogic.isWildcardRowChallengeLevel
            && challengeLogic.canAddChallengeRow {
            row.setAllWildcards()
        } else if challengeLogic.isRandomWildcardChallengeLevel {
            row.addRandomWildcard()
        }
    }

    func updateMap(_ row: [TokenData]) {
        row.forEach { tData in
            tData.id = tokenIDCounter.incremented()
            tDataMap[tData.id] = tData
        }
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

    func removeRowForMatch(tokenID: TokenID) -> TokenDataRow {
        guard let index = rowIndexForID(tokenID) else {
            // TODO: end game?
            return []
        }

        for tData in rows[index] {
            tDataMap.removeValue(forKey: tData.id)
        }

        return rows.remove(at: index)
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
                let row = removeRowForMatch(tokenID: tDataPair.tData1.id)
                rowsCleared += 1
                return .targetMatch(tDataPair: tDataPair,
                                    rowsCleared: rowsCleared,
                                    rowBonus: row.bonus)
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

    func trainingHelperIDs() -> [TokenID] {
        var tokenIDs = [TokenID]()

        rows.forEach {
            if let tokenID = $0.trainingHelperID() {
                tokenIDs.append(tokenID)
            }
        }

        return tokenIDs
    }
}

enum RowBonus: Int {
    case none = 0
    case uniform = 10
    case wildcard = 20
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

        tData1.isTrainingHelper = false
        tData2.isTrainingHelper = false

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

