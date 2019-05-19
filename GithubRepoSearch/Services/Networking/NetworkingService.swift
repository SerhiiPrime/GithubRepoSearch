//
//  NetworkingService.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import ReactiveSwift
import Result

typealias APIRequestEndpoint = String
typealias APIRequestParameters = [String: Any]
typealias APIRequestHeaders = [String: String]

protocol APIRequest {
    var endpoint: APIRequestEndpoint { get }
    var method: HTTPMethod { get }
    var parameters: APIRequestParameters? { get }
    var headers: APIRequestHeaders? { get }
    var parameterEncoding: ParameterEncoding { get }
}

enum HTTPMethod: String {
    case head = "HEAD"
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum ParameterEncoding {
    case url
    case json
}

enum APIRequestContentType: String {
    case json = "application/json"
    case data = "multipart/form-data"
}

// MARK: - API Response

struct APIResponse {
    let value: Data?
    let response: HTTPURLResponse?

    init(value: Data?, response: HTTPURLResponse?) {
        self.value = value
        self.response = response
    }
}

// MARK: - Error

enum APIError: Error {
    case dataMapping
    case request(Error)
}

protocol NetworkingService {
    //TODO: add error
    func searchRepos(query: String, page: Int, limit: Int, sort: String) -> SignalProducer<[Repo], APIError>
}

final class NetworkingServiceImpl: NetworkingService {

    static let shared = NetworkingServiceImpl()
    private lazy var session: URLSession = URLSession(configuration: URLSessionConfiguration.default)

    private init() {
    }

    func searchRepos(query: String, page: Int, limit: Int, sort: String) -> SignalProducer<[Repo], APIError> {
        let request = GetReposRequest(query: query, page: page, limit: limit, sort: sort)

        return getProducer(request: request)
            .attemptMap { response in
                guard let data = response.value else { return Result(error: .dataMapping) }
                do {
                    return Result(value: try JSONDecoder().decode(ReposBox.self, from: data).items)
                } catch {
                    return Result(error: .dataMapping)
                }
            }
            .observe(on:QueueScheduler(qos: .utility, name: "github.search"))
    }

    private func getProducer(request: APIRequest) -> SignalProducer<APIResponse, APIError> {
        logRequest(for: request) //TODO: remove
        return SignalProducer(result: encode(request: request)
            .mapError(APIError.request))
            .flatMap(.latest) { [weak self] (request: URLRequest) -> SignalProducer<APIResponse, APIError> in
                guard let strongSelf = self else { return .empty }
                return SignalProducer { (observer, lifetime) in
                    let task = strongSelf.session.dataTask(with: request) { (data, response, error) in
                        let httpResponse = response as? HTTPURLResponse
                        let result: Result<APIResponse, APIError> = error.map {
                            .failure(.request($0 as NSError))
                            } ?? .success(APIResponse(value: data, response: httpResponse))

                        strongSelf.logResult(for: result) //TODO: remove
                        switch result {
                        case let .success(response):
                            observer.send(value: response)
                            observer.sendCompleted()
                        case let .failure(error):
                            observer.send(error: error)
                        }
                    }
                    task.resume()
                    lifetime.observeEnded(task.cancel)
                }
        }
    }

    private func logRequest(for apiRequest: APIRequest) {
        let result = """
        \(apiRequest.method.rawValue) '\(apiRequest.endpoint)'
        headers: \(apiRequest.headers ?? ["headers": "absent"])
        parameters: \(apiRequest.parameters ?? ["parameters": "absent"])\n
        """
        print(result)
    }

    private func logResult(for result: Result<APIResponse, APIError>) {

        switch result {
        case let .success(response):
            if let data = response.value {
                let json = try? JSONSerialization.jsonObject(with: data, options: .init(rawValue: 0))
                let jsonMsg = "SUCCESS:\n\(json ?? "--")"
                print(jsonMsg)
            }
        case let .failure(error):
            print("Error: \(error.localizedDescription)")
        }
    }
}

extension NetworkingServiceImpl {

    private func encode(request apiRequest: APIRequest) -> Result<URLRequest, NSError> {
        let requestResult = urlRequest(from: apiRequest)
        guard let request = requestResult.value else {
            return requestResult
        }

        switch apiRequest.parameterEncoding {
        case .json:
            return requestWithBodyParameters(from: request, endpoint: apiRequest.endpoint, parameters: apiRequest.parameters)
        case .url:
            return requestWithQueryParameters(from: request, endpoint: apiRequest.endpoint, parameters: apiRequest.parameters)
        }
    }

    private func requestWithQueryParameters(from request: URLRequest, endpoint: String, parameters: APIRequestParameters?) -> Result<URLRequest, NSError> {
        var resultRequest = request
        var components = URL(string: endpoint).flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        components?.queryItems = parameters?
            .flatMap(URLEncoder.queryComponents)
            .map(URLQueryItem.init)
        resultRequest.url = components?.url
        return .success(resultRequest)
    }

    private func requestWithBodyParameters(from request: URLRequest, endpoint: String, parameters: APIRequestParameters?) -> Result<URLRequest, NSError> {
        guard let parameters = parameters else { return .success(request) }
        var resultRequest = request
        if let data = try? JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted) {
            resultRequest.setValue(APIRequestContentType.json.rawValue, forHTTPHeaderField: "Content-Type")
            resultRequest.httpBody = data
        } else {
            return .failure(NSError(domain: "github.search", code: NSFormattingError))
        }
        return .success(resultRequest)
    }

    private func urlRequest(from apiRequest: APIRequest) -> Result<URLRequest, NSError> {
        guard let url = URL(string: apiRequest.endpoint) else {
            return .failure(NSError(domain: "github.search", code: NSURLErrorBadURL))
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.allHTTPHeaderFields = apiRequest.headers
        urlRequest.httpMethod = apiRequest.method.rawValue
        return .success(urlRequest)
    }
}

extension NetworkingServiceImpl {
    struct ReposBox: Decodable {
        let items: [RepoEntity]
    }
}
