//
//  APIEndpoint.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/19/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

enum APIEndpoint {
    private static let baseURL = "https://api.github.com/"

    case getRepos

    var stringValue: String {
        let result: String

        switch self {
        case .getRepos:
            result = "search/repositories"
        }

        return APIEndpoint.baseURL + result
    }
}
