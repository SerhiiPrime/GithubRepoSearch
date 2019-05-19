//
//  GetReposRequest.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/19/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

struct GetReposRequest: APIRequest {

    let method = HTTPMethod.get
    let headers: [String: String]? = nil
    let parameterEncoding: ParameterEncoding = .url
    let endpoint: String = APIEndpoint.getRepos.stringValue
    let parameters: [String: Any]?

    init(query: String, page: Int, limit: Int, sort: String?) {
        var params: [String : Any] = [
            "q" : query,
            "page": page,
            "per_page": limit
        ]
        sort.map { params["sort"] = $0 }
        parameters = params
    }
}
