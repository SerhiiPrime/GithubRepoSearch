//
//  NetworkReachability.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/19/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import Reachability

final class NetworkReachability {
    static func isNetworkConnectionExist() -> Bool {
        guard let reachability = Reachability()?.connection else { return false }
        return reachability != .none
    }
}
