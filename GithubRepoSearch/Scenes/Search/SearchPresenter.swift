//
//  SearchPresenter.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import DeepDiff

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
        let viewState = SearchListViewState(state: state)
        output?.update(state: viewState)
    }
}

private extension SearchListViewState {
    init(state: SearchListState) {
        switch state {
        case .idle:
            self = .idle
        case .loading(.new, _):
            self = .loading(.new)
        case let .loading(.fresh(model), _):
            self = .loading(.fresh(prevModel: model.map(SearchListViewState.ViewModel.init)))
        case let .loading(.more(model), _):
            self = .loading(.more(prevModel: .init(model: model)))
        case let .loaded(.success(model)):
            self = .loaded(.success(.init(model: model)))
        case let .loaded(.failure(model, error)):
            self = .loaded(.failure(prev: model.map(SearchListViewState.ViewModel.init), error.localizedDescription))
        }
    }
}

private extension SearchListViewState.ViewModel {
    init(model: SearchListState.Model) {
        repos = model.repos.map { RepoViewModel(name: $0.name, urlLabel: $0.htmlURLString) }
        hasMore = model.hasMore
    }
}

extension RepoViewModel: DiffAware {
    var diffId: Int {
        return 0
    }
    static func compareContent(_ a: RepoViewModel, _ b: RepoViewModel) -> Bool {
        return a.name == b.name && a.urlLabel == b.urlLabel
    }
}
