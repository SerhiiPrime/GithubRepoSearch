//
//  APIRouter.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import Alamofire

enum APIRouter: URLRequestConvertible {

    private enum Constants {
        static let baseURL = "https://api.github.com/"
    }

    case getRepos(query: String, sort: String?)

    var method: HTTPMethod{
        switch self {
        case .getRepos:
            return .get
        }
    }

    var path: String {
        switch self {
        case .getRepos:
            return "search/repositories"
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case let .getRepos(query, sort):
            var params = ["q" : query]
            sort.map { params["sort"] = $0 }
            return params
        }
    }

    var encoding: ParameterEncoding {
        switch self {
        case .getRepos:
            return URLEncoding.default
        }
    }

    // MARK: URLRequestConvertible

    func asURLRequest() throws -> URLRequest {
        let url = try Constants.baseURL.asURL()

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        return try encoding.encode(urlRequest, with: parameters)
    }
}
