//
//  ReposDataProvider.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import ReactiveCocoa
import ReactiveSwift
import Result

typealias ProviderRepos = (repos: [Repo], hasMore: Bool)
protocol ReposDataProvider {
    func getLastSearchResult() -> [Repo]
    func getInitialRepos(query: String) -> SignalProducer<ProviderRepos, Error>
    func getMoreRepos() -> SignalProducer<ProviderRepos, Error>
    var query: String { get }
}

class ReposDataProviderImpl: ReposDataProvider {
    private let networkingService: NetworkingService
    private let reposDatabaseService: ReposDatabaseService
    private var page: Page = Page()
    private(set) var query: String = String()

    private enum LocalConstants {
        static let sort = "stars"
    }

    init(networkingService: NetworkingService, reposDatabaseService: ReposDatabaseService) {
        self.networkingService = networkingService
        self.reposDatabaseService = reposDatabaseService
    }

    func getLastSearchResult() -> [Repo] {
        return reposDatabaseService.getAllRepos()
    }

    func getInitialRepos(query: String) -> SignalProducer<ProviderRepos, Error> {
        self.query = query
        page.reset()
        return loadRepos(with: query)
            .attemptMap { [weak self] result -> Result<ProviderRepos, Error> in
                self?.reposDatabaseService.saveRepos(result.repos, removeOld: true)
                return Result(value: result)
            }
    }

    func getMoreRepos() -> SignalProducer<ProviderRepos, Error> {
        guard page.hasMore else { return SignalProducer(value: ([], false)) }
        page.next()
        return loadRepos(with: query)
            .attemptMap { [weak self] result -> Result<ProviderRepos, Error> in
                self?.reposDatabaseService.saveRepos(result.repos, removeOld: false)
                return Result(value: result)
        }
    }

    private func loadRepos(with query: String) -> SignalProducer<ProviderRepos, Error> {
        return networkingService.searchRepos(query: query, page: page.page, limit: page.limit, sort: LocalConstants.sort)
            .take(duringLifetimeOf: self)
            .map { [weak self] response in
                guard let strongSelf = self else { return ([], false) }
                strongSelf.page.hasMore = response.count == strongSelf.page.limit
                return (response, strongSelf.page.hasMore)
            }
    }

//    private func loadRepos(with query: String) -> SignalProducer<ProviderRepos, Error> {
//        let firstRequest = networkingService.searchRepos(query: query, page: page.page, limit: page.limit, sort: LocalConstants.sort)
//            .take(duringLifetimeOf: self)
//        page.next()
//
//        let secondRequest = networkingService.searchRepos(query: query, page: page.page, limit: page.limit, sort: LocalConstants.sort)
//            .take(duringLifetimeOf: self)
//        page.next()
//
//        return firstRequest.concat(secondRequest).map { [weak self] response -> ProviderRepos in
//            guard let strongSelf = self else { return ([], false) }
//            strongSelf.page.hasMore = response.count == strongSelf.page.limit
//            return (response, strongSelf.page.hasMore)
//        }
//    }
}
