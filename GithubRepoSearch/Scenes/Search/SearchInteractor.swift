//
//  SearchInteractor.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import ReactiveSwift

// MARK: - Protocols

protocol SearchInteractorInput {
    func setup()
    func search(query: String)
    func cancelSearch()
    func showRepo(at index: Int)
}

protocol SearchInteractorOutput {

}

// MARK: - State

enum SearchListState {
    case idle
    case loading(Loading, Disposable?)
    case loaded(Result)

    enum Loading {
        case new
        case fresh(Model?)
        case more(Model)
    }

    enum Result {
        case success(Model)
        case failure(prev: Model?, Error)
    }

    struct Model {
        let repos: [Repo]
        let hasMore: Bool

    }

    enum Error: Swift.Error {
        case networking
    }
}

// MARK: - Implementation

final class SearchInteractor {
    private let output: SearchInteractorOutput

    init(output: SearchInteractorOutput) {
        self.output = output
    }
}

extension SearchInteractor: SearchInteractorInput {
    func setup() {
        // perform any initial tasks here (i.e. data loading, passing existing data, etc.)
        // and pass results to the output (i.e. `output.refreshUsers(with: users)`)
    }

    func search(query: String) {
        
    }

    func cancelSearch() {
        
    }

    func showRepo(at index: Int) {

    }
}
