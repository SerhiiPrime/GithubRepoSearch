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
    func loadMore()
    func refresh()
    func cancelSearch()
    func showRepo(at index: Int)
}

protocol SearchInteractorOutput {
    func update(state: SearchListState)
    func showRepo(with url: URL)
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
    private let provider: ReposDataProvider
    private var state: SearchListState = .idle {
        didSet {
            output.update(state: state)
        }
    }

    init(output: SearchInteractorOutput, provider: ReposDataProvider) {
        self.output = output
        self.provider = provider
    }
}

extension SearchInteractor: SearchInteractorInput {
    func setup() {
        guard state.isIdle else { return }
        state = .idle
    }

    func search(query: String) {
        state.cancelLoading()
        guard query.isNotEmpty else {
            cancelSearch()
            return
        }
        state = .loading(.new, nil)

        let disposable = loadInitial(query: query)
        if state.isLoadingNew {
            state = .loading(.new, disposable)
        }
    }

    func loadMore() {
        guard state.isLoaded, let model = state.model, model.hasMore else { return }
        state = .loading(.more(model), nil)

        let disposable = loadMore(initialModel: model)
        if state.isLoadingMore {
            state = .loading(.more(model), disposable)
        }
    }

    func refresh() {
        guard provider.query.isNotEmpty else { return }
        state.cancelLoading()
        state = .loading(.fresh(state.model), nil)

        let disposable = loadInitial(query: provider.query)
        if state.isLoadingFresh {
            state = .loading(.fresh(state.model), disposable)
        }
    }

    func cancelSearch() {
        state.cancelLoading()
        guard state.isIdle == false else { return }
        state = .idle
    }

    func showRepo(at index: Int) {
        guard let repoUrlString = state.model?.repos[safe: index]?.htmlURLString, let repoUrl = URL(string: repoUrlString) else { return }
        output.showRepo(with: repoUrl)
    }

    private func loadInitial(query: String) -> Disposable {
        return provider.getInitialRepos(query: query)
            .on(failed: { [weak self] error in
                guard let strongSelf = self else { return }
                strongSelf.state = .loaded(.failure(prev: strongSelf.state.model, .networking))
            }, value: { [weak self] response in
                guard let strongSelf = self else { return }
                let model = SearchListState.Model.init(repos: response.repos, hasMore: response.hasMore)
                strongSelf.state = .loaded(.success(model))
            })
            .start()
    }

    private func loadMore(initialModel: SearchListState.Model) -> Disposable {
        return provider.getMoreRepos()
            .on(failed: { [weak self] error in
                guard let strongSelf = self else { return }
                strongSelf.state = .loaded(.failure(prev: strongSelf.state.model, .networking))
            }, value: { [weak self] response in
                guard let strongSelf = self else { return }

                let model = SearchListState.Model.init(repos: initialModel.repos + response.repos, hasMore: response.hasMore)
                strongSelf.state = .loaded(.success(model))
            })
            .start()
    }
}

// MARK: - State Prisms

extension SearchListState {
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
    var isLoadingNew: Bool {
        if case .loading(.new, _) = self { return true }
        return false
    }
    var isLoadingFresh: Bool {
        if case .loading(.fresh, _) = self { return true }
        return false
    }
    var isLoadingMore: Bool {
        if case .loading(.more, _) = self { return true }
        return false
    }
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}

extension SearchListState {
    var model: Model? {
        switch self {
        case .idle: return nil
        case .loading(.new, _): return nil
        case let .loading(.fresh(prevModel), _): return prevModel
        case let .loading(.more(prevModel), _): return prevModel
        case let .loaded(.success(currModel)): return currModel
        case let .loaded(.failure(prevModel, _)): return prevModel
        }
    }
}

extension SearchListState {
    func cancelLoading() {
        switch self {
        case .idle, .loaded:
            break
        case let .loading(_, disposable):
            disposable?.dispose()
        }
    }
}
