//
//  SearchRouter.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import UIKit

// MARK: - Protocol

protocol SearchRouting {
    func showRepo(with url: URL)
}

// MARK: - Implementation

final class SearchRouter {
    private weak var viewController: SearchViewController?

    init(viewController: SearchViewController) {
        self.viewController = viewController
    }
}

extension SearchRouter: SearchRouting {
    func showRepo(with url: URL) {
        let controller = BrowserViewController.scene(with: url)
        controller.modalPresentationStyle = .overCurrentContext
        DispatchQueue.main.async {
            self.viewController?.present(controller, animated: true)
        }
    }
}
