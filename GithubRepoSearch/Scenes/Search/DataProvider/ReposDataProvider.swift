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

typealias ProviderRepos = (repos: [Repo], hasMore: Bool)
protocol ReposDataProvider {
    func getInitialRepos() -> SignalProducer<ProviderRepos, Error>
    func getMoreRepos() -> SignalProducer<ProviderRepos, Error>
}

class ReposDataProviderImpl: ReposDataProvider {
    private let networkingService: NetworkingService
    private let query: String
    private var page: Page

    init(query: String, networkingService: NetworkingService, page: Page) {
        self.query = query
        self.networkingService = networkingService
        self.page = page
    }

    func getInitialRepos() -> SignalProducer<ProviderRepos, Error> {
        page.reset()
        return loadRepos(with: query)
    }

    func getMoreRepos() -> SignalProducer<ProviderRepos, Error> {
        guard page.hasMore else { return SignalProducer(value: ([], false)) }
        page.next()
        return loadRepos(with: query)
    }

    private func loadRepos(with query: String) -> SignalProducer<ProviderRepos, Error> {
        return networkingService.searchRepos(query: query, limit: page.limit, offset: page.offset)
            .take(duringLifetimeOf: self)
            .map { [weak self] response in
                guard let strongSelf = self else { return ([], false) }
                strongSelf.page.hasMore = response.count == strongSelf.page.limit
                return (response, strongSelf.page.hasMore)
            }
    }
}
