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
    
}

// MARK: - Implementation

final class SearchRouter {
    private weak var viewController: SearchViewController?

    init(viewController: SearchViewController) {
        self.viewController = viewController
    }
}

extension SearchRouter: SearchRouting {
    
}
