//
//  StatData.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 1/13/20.
//  Copyright © 2020 Ben Balcomb. All rights reserved.
//

import Foundation

typealias SkillLevel = Int
extension SkillLevel {
    static var basic: SkillLevel {
        1
    }
    static var expert: SkillLevel {
        2
    }
}

struct StatData: Decodable {
    var highScore: Int
    var averageScore: Double
    var games: Int
    var level: SkillLevel

    static func isValidAverageScore(_ score: Double) -> Bool {
        score >= 0.0
    }

    static func defaultStats(expertModeOn: Bool) -> StatData {
        StatData(highScore: Int.max,
                 averageScore: -1.0,
                 games: 0,
                 level: expertModeOn ? .expert : .basic)
    }

    static func isPersonalBest(score: Int,
                               level: SkillLevel) -> Bool {

        let userDefaults = UserDefaults.standard
        let bestKey = self.statKey(name: "Best",
                                   level: level)

        guard score > userDefaults.integer(forKey: bestKey) else {
            return false
        }

        userDefaults.set(score, forKey: bestKey)

        return true
    }

    static func updatedPersonalAverage(score: Int,
                                       level: SkillLevel,
                                       trainingModeOn: Bool) -> Double {

        let userDefaults = UserDefaults.standard
        let averageKey = self.statKey(name: "Average",
                                      level: level)
        let gamesKey = self.statKey(name: "Games",
                                    level: level)

        let currentAverage = userDefaults.double(forKey: averageKey)

        if trainingModeOn {
            return currentAverage
        }

        let currentGames = userDefaults.double(forKey: gamesKey)
        let newGames = currentGames + 1
        let newAverage = ((currentAverage * currentGames) + Double(score)) / newGames

        userDefaults.set(newAverage,
                         forKey: averageKey)
        userDefaults.set(newGames,
                         forKey: gamesKey)

        return newAverage
    }

    static func statKey(name: String, level: SkillLevel) -> String {
        "TT" + name + "Key" + String(level)
    }
}

struct StatRequest {

    static func baseComponents(pathName: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "tokentrap.com"
        components.path = "/" + pathName + ".py"

        return components
    }

    static func levelQueryItem(_ expertModeOn: Bool) -> URLQueryItem {
        let value: SkillLevel = expertModeOn ? .expert : .basic

        return URLQueryItem(name: "level",
                            value: String(value))
    }

    static func updateStats(score: Int,
                            expertModeOn: Bool) {
        var components = self.baseComponents(pathName: "updateStats")
        components.queryItems = [self.levelQueryItem(expertModeOn),
                                 URLQueryItem(name: "ios",
                                              value: "1"),
                                 URLQueryItem(name: "score",
                                              value: String(score))]
        if let url = components.url {
            URLSession.shared.dataTask(with: url).resume()
        }
    }

    static func getStats(expertModeOn: Bool,
                         completion: @escaping (_ data: StatData?) -> Void) {
        var components = self.baseComponents(pathName: "getStats")
        components.queryItems = [self.levelQueryItem(expertModeOn)]

        guard let url = components.url else { return }
        var request = URLRequest(url: url)
        request.timeoutInterval = 3

        URLSession.shared.dataTask(with: request) { (data, response, error) in
            completion(self.decodeStatData(data))
        }
        .resume()
    }

    static func decodeStatData(_ rawData: Data?) -> StatData? {
        var statData: StatData?

        if let data = rawData {
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                statData = try decoder.decode(StatData.self,
                                              from: data)
            } catch {
                print("failed to decode JSON from getStats")
            }
        }

        return statData
    }
}
