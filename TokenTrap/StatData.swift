//
//  StatData.swift
//  TokenTrap
//
//  Created by Ben Balcomb on 1/13/20.
//  Copyright © 2020 Ben Balcomb. All rights reserved.
//

import Foundation

struct StatData: Decodable {
    var highScore: Int
    var averageScore: Double
    var games: Int
    var level: Int
}

struct StatRequest {

    static func components(_ pathName: String) -> URLComponents {
        var components = URLComponents()
        components.scheme = "http"
        components.host = "tokentrap.com"
        components.path = "/" + pathName + ".py"

        return components
    }

    static func levelQueryItem(_ expertModeOn: Bool) -> URLQueryItem {
        URLQueryItem(name: "level",
                     value: expertModeOn ? "2" : "1")
    }

    static func updateStats(score: Int,
                            expertModeOn: Bool) {
        var components = self.components("updateStats")
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
        var components = self.components("getStats")
        components.queryItems = [self.levelQueryItem(expertModeOn)]

        guard let url = components.url else { return }

        let task = URLSession.shared.dataTask(with: url) { (rawData, response, error) in
            guard let data = rawData else { return }

            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let stats = try decoder.decode(StatData.self,
                                               from: data)
                completion(stats)
            } catch {
                completion(nil)
            }
        }
        task.resume()
    }
}
