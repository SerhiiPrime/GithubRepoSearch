//
//  ReposDatabaseService.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/19/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import RealmSwift

protocol ReposDatabaseService: class {
    func getAllRepos() -> [Repo]
    func searchRepos(query: String) -> [Repo]
    func saveRepos(_ repos: [Repo], removeOld: Bool)
}

class ReposDatabaseServiceImpl: ReposDatabaseService {

    static let shared: ReposDatabaseService = ReposDatabaseServiceImpl(
        databaseService: DatabaseServiceImpl.shared
    )

    private let databaseService: DatabaseService

    private init(databaseService: DatabaseService) {
        self.databaseService = databaseService
    }

    func getAllRepos() -> [Repo] {
        return databaseService
            .db()
            .objects(RepoObject.self)
            .sorted(byKeyPath: #keyPath(RepoObject.starsCount), ascending: false)
            .map(RepoEntity.init)
    }

    func searchRepos(query: String) -> [Repo] {
        return databaseService
            .db()
            .objects(RepoObject.self)
            .filter("\(#keyPath(RepoObject.name)) CONTAINS %@", query)
            .sorted(byKeyPath: #keyPath(RepoObject.starsCount), ascending: false)
            .map(RepoEntity.init)
    }

    func saveRepos(_ repos: [Repo], removeOld: Bool) {
        let realm = databaseService.db()

        // Remove old in case of new search
        if removeOld {
            try! realm.write {
                realm.deleteAll()
            }
        }

        //TODO: throw error instead of force unwrapping
        try! realm.write {
            realm.add(repos.map(RepoObject.init), update: true)
        }
    }
}
