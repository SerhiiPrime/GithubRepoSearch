//
//  SearchViewController.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import UIKit
import ReactiveCocoa
import ReactiveSwift

// MARK: - Protocols

protocol SearchViewControllerInput {
    func update(state: SearchListViewState)
}

protocol SearchViewControllerOutput {
    func setup()
    func search(query: String)
    func cancelSearch()
    func loadMore()
    func refresh()
    func showRepo(at index: Int)
}

// MARK: - View State

enum SearchListViewState {
    case idle
    case loading(Loading)
    case loaded(Result)

    enum Loading {
        case new
        case fresh(prevModel: ViewModel?)
        case more(prevModel: ViewModel)
    }

    enum Result {
        case success(ViewModel)
        case failure(prev: ViewModel?, String)
    }

    struct ViewModel {
        let repos: [RepoViewModel]
        let hasMore: Bool
    }
}

// MARK: - Implementation

final class SearchViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    var output: SearchViewControllerOutput?
    private var state: SearchListViewState = .idle

    private enum LocalConstants {
        static let cellHeight: CGFloat = 72
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        output?.setup()
    }

    private func setupUI() {
        searchBar.delegate = self
        searchBar.reactive
            .continuousTextValues
            .skipNil()
            .throttle(0.5, on: QueueScheduler.main)
            .observeValues { [weak self] text in
                self?.output?.search(query: text)
        }

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(cellType: RepoTableViewCell.self)
    }
}

extension SearchViewController: SearchViewControllerInput {
    func update(state: SearchListViewState) {
        DispatchQueue.main.async {

        }
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state.viewModel?.repos.count ?? 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return LocalConstants.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let repo = state.viewModel?.repos[safe: indexPath.row] else { return UITableViewCell() }

        if let viewModel = state.viewModel,
            state.isLoaded
                && viewModel.hasMore
                && shouldStartLoadingMore(at: indexPath, whenScrolledThroughNumberOfRepos: viewModel.repos.count) {
            output?.loadMore()
        }

        return tableView
            .dequeueReusableCell(ofType: RepoTableViewCell.self, at: indexPath)
            .setup(with: repo)
    }

    private func shouldStartLoadingMore(at indexPath: IndexPath, whenScrolledThroughNumberOfRepos reposNumber: Int) -> Bool {
        return indexPath.row == reposNumber - 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        output?.showRepo(at: indexPath.row)
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.resignFirstResponder()
        output?.cancelSearch()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
}

// MARK: - View State Prisms

extension SearchListViewState {
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }
}

extension SearchListViewState {
    var viewModel: SearchListViewState.ViewModel? {
        switch self {
        case .idle: return nil
        case .loading(.new): return nil
        case let .loading(.fresh(prevModel)): return prevModel
        case let .loading(.more(prevModel)): return prevModel
        case let .loaded(.success(currModel)): return currModel
        case let .loaded(.failure(prevModel, _)): return prevModel
        }
    }
}
