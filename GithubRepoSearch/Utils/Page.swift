//
//  Page.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

struct Page {
    private static let defaultLimitValue = 10
    private static let defaultPage = 1

    let limit: Int
    var hasMore: Bool = true
    private(set) var page: Int

    init(limit: Int = Page.defaultLimitValue, page: Int = Page.defaultPage) {
        self.limit   = limit
        self.page  = page
        self.hasMore = true
    }

    mutating func reset() {
        page  = 1
        hasMore = true
    }

    mutating func next() {
        page += 1
    }
}
