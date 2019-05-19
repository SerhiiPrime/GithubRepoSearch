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
    func saveRepos(_ repos: [Repo])
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

    func saveRepos(_ repos: [Repo]) {
        let realm = databaseService.db()
        // We want to have only repos from last search query
        try! realm.write {
            realm.deleteAll()
        }

        //TODO: throw error instead of force unwrapping
        try! realm.write {
            realm.add(repos.map(RepoObject.init))
        }
    }
}
