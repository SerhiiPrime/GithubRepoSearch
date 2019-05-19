//
//  DatabaseService.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/19/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import RealmSwift

// MARK: - Protool

protocol DatabaseService {
    func db() -> Realm
}

// MARK: - Implementation

class DatabaseServiceImpl: DatabaseService {
    static let shared: DatabaseService = DatabaseServiceImpl(dbName: "search")
    
    private static let currentSchemaVersion: UInt64 = 1
    private let dbFileURL: URL?
    private let realmConfig: Realm.Configuration
    
    private init(dbName: String) {
        let documentDir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        dbFileURL = documentDir?.appendingPathComponent(dbName).appendingPathExtension("realm")
        realmConfig = Realm.Configuration(
            fileURL: dbFileURL,
            schemaVersion: DatabaseServiceImpl.currentSchemaVersion
        )
    }
    
    func db() -> Realm {
        return try! Realm(configuration: realmConfig)
    }
}
