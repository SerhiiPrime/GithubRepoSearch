//
//  NetworkingService.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import ReactiveSwift

protocol NetworkingService {
    //TODO: add error
    func getRepos(query: String) -> SignalProducer<[Repo], Error>
}

