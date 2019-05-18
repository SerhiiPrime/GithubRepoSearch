//
//  SearchPresenter.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

// MARK: - Protocols

protocol SearchPresenterInput: class {
    func update(state: SearchListState)
}

protocol SearchPresenterOutput: class {
    func update(state: SearchListViewState)
}

// MARK: - Implementation

final class SearchPresenter {
    private weak var output: SearchPresenterOutput?
    private let router: SearchRouting

    init(output: SearchPresenterOutput, router: SearchRouting) {
        self.output = output
        self.router = router
    }
}

extension SearchPresenter: SearchPresenterInput {
    func update(state: SearchListState) {
        
    }
}
