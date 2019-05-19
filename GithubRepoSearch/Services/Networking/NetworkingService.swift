//
//  NetworkingService.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import ReactiveSwift
import Alamofire
import Result

protocol NetworkingService {
    //TODO: add error
    func searchRepos(query: String, limit: Int, offset: Int, sort: String) -> SignalProducer<[Repo], Error>
}

final class NetworkingServiceImpl: NetworkingService {

    static let shared = NetworkingServiceImpl(session: Alamofire.Session(configuration: URLSessionConfiguration.default))
    private let session: Session

    private init(session: Session) {
        self.session = session
    }

    func searchRepos(query: String, limit: Int, offset: Int, sort: String) -> SignalProducer<[Repo], Error> {
        return getProducer(endpoint: APIRouter.getRepos(query: query, sort: sort)).attemptMap { data in
            do {
                return Result(value: try JSONDecoder().decode(ReposBox.self, from: data).items)
            } catch let error {
                return Result(error: error)
            }
        }
    }

    private func getProducer(endpoint: APIRouter) -> SignalProducer<Data, Error> {
        return SignalProducer { (observer, disposable) in
            self.session
                .request(endpoint)
                .logRequest()
                .validate()
                .responseData { (response) in
                    //TODO: Remove print
                    response.data.map { print(String(bytes: $0, encoding: .utf8)) }

                    switch response.result {
                    case .success(let data):
                        observer.send(value: data)
                        observer.sendCompleted()
                    case .failure(let error):
                        observer.send(error: error)
                    }
            }
        }
    }
}

extension NetworkingServiceImpl {
    struct ReposBox: Decodable {
        let items: [RepoEntity]
    }
}
