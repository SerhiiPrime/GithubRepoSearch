//
//  SearchConfigurator.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

extension SearchViewController: SearchPresenterOutput { }
extension SearchInteractor: SearchViewControllerOutput { }
extension SearchPresenter: SearchInteractorOutput { }

struct SearchConfigurator {
    static func scene() -> SearchViewController {
        let viewController = SearchViewController(nibName: "SearchViewController", bundle: nil)
        let router = SearchRouter(viewController: viewController)
        let presenter = SearchPresenter(output: viewController, router: router)
        let interactor = SearchInteractor(
            output: presenter,
            provider: ReposDataProviderImpl(networkingService: NetworkingServiceImpl.shared, reposDatabaseService: ReposDatabaseServiceImpl.shared)
        )
        viewController.output = interactor
        return viewController
    }
}
