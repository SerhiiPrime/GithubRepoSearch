//
//  Repo.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: - Protocol

@objc protocol Repo {
    var id: String { get }
    var name: String { get }
    var htmlURLString: String { get }
    var starsCount: Int { get }
}

// MARK: - Plain Entity Object + Decodable

class RepoEntity: Repo, Decodable {
    let id: String
    let name: String
    let htmlURLString: String
    let starsCount: Int

    init(id: String, name: String, htmlURLString: String, starsCount: Int) {
        self.id = id
        self.name = name
        self.htmlURLString = htmlURLString
        self.starsCount = starsCount
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, htmlURLString = "html_url", starsCount = "stargazers_count"
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let id = try container.decode(String.self, forKey: .id)
        let name = try container.decode(String.self, forKey: .name)
        let htmlURLString = try container.decode(String.self, forKey: .htmlURLString)
        let starsCount = try container.decode(Int.self, forKey: .starsCount)
        self.init(id: id, name: name, htmlURLString: htmlURLString, starsCount: starsCount)
    }

    convenience init(repo: Repo) {
        self.init(id: repo.id, name: repo.name, htmlURLString: repo.htmlURLString, starsCount: repo.starsCount)
    }
}

// MARK: - Realm Object

class RepoObject: Object, Repo {
    @objc dynamic var id: String = ""
    @objc dynamic var name: String = ""
    @objc dynamic var htmlURLString: String = ""
    @objc dynamic var starsCount: Int = 0

    override static func primaryKey() -> String? {
        return #keyPath(RepoObject.id)
    }

    override static func indexedProperties() -> [String] {
        return [#keyPath(RepoObject.name)]
    }

    convenience init(repo: Repo) {
        self.init()
        id = repo.id
        name = repo.name
        htmlURLString = repo.htmlURLString
        starsCount = repo.starsCount
    }
}
