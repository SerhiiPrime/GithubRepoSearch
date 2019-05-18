//
//  SearchInteractor.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

// MARK: - Protocols

protocol SearchInteractorInput {
    func setup()
}

protocol SearchInteractorOutput {

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
}
