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
    func getInitialRepos(query: String) -> SignalProducer<ProviderRepos, APIError>
    func getMoreRepos() -> SignalProducer<ProviderRepos, APIError>
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

    func getInitialRepos(query: String) -> SignalProducer<ProviderRepos, APIError> {
        self.query = query
        page.reset()

        if NetworkReachability.isNetworkConnectionExist() {
            return loadRepos(with: query).attemptMap { [weak self] result -> Result<ProviderRepos, APIError> in
                self?.reposDatabaseService.saveRepos(result.repos, removeOld: true)
                return Result(value: result)
            }
        } else {
            let result = ProviderRepos(repos: reposDatabaseService.searchRepos(query: query), hasMore: false)
            return SignalProducer(result: Result(value: result))
        }
    }

    func getMoreRepos() -> SignalProducer<ProviderRepos, APIError> {
        guard page.hasMore , NetworkReachability.isNetworkConnectionExist() else { return SignalProducer(value: ([], false)) }
        page.next()
        return loadRepos(with: query).attemptMap { [weak self] result -> Result<ProviderRepos, APIError> in
            self?.reposDatabaseService.saveRepos(result.repos, removeOld: false)
            return Result(value: result)
        }
    }

    private func loadRepos(with query: String) -> SignalProducer<ProviderRepos, APIError> {
        return networkingService.searchRepos(query: query, page: page.page, limit: page.limit, sort: LocalConstants.sort)
            .map { [weak self]  (repos) -> ProviderRepos in
                guard let strongSelf = self else { return ([], false) }
                strongSelf.page.hasMore = repos.count == strongSelf.page.limit
                return (repos, strongSelf.page.hasMore)
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
