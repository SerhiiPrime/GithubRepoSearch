//
//  Page.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

struct Page {
    private static let defaultLimitValue = 20
    private static let defaultOffsetValue = 0

    let limit: Int
    var hasMore: Bool = true
    private(set) var offset: Int = 0

    init(limit: Int = Page.defaultLimitValue, offset: Int = Page.defaultOffsetValue) {
        self.limit   = limit
        self.offset  = offset
        self.hasMore = true
    }

    mutating func reset() {
        offset  = 0
        hasMore = true
    }

    mutating func next() {
        offset += limit
    }
}
