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
import DeepDiff

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
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var tableView: UITableView!
    private lazy var refreshControl = UIRefreshControl()
    private lazy var loadingLabel: UILabel = {
        let label = UILabel()
        label.frame = tableView.bounds
        label.center = tableView.center
        label.text = "Loading..."
        label.textAlignment = .center
        label.center = tableView.center
        label.textColor = UIColor.black.withAlphaComponent(0.5)
        label.font = UIFont.boldSystemFont(ofSize: 27)
        return label
    }()

    private let moreActivityIndicatorView: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .gray)
        activityIndicator.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        activityIndicator.startAnimating()
        return activityIndicator
    }()

    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.frame = tableView.bounds
        label.center = tableView.center
        label.numberOfLines = 0
        label.textColor = UIColor.black.withAlphaComponent(0.3)
        label.font = UIFont.boldSystemFont(ofSize: 24)
        return label
    }()

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
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(refreshAction), for: .valueChanged)
    }

    @objc private func refreshAction() {
        guard state.isLoaded || state.isFailed else {
            refreshControl.endRefreshing()
            return
        }
        output?.refresh()
    }
}

extension SearchViewController: SearchViewControllerInput {
    func update(state: SearchListViewState) {
        DispatchQueue.main.async {
            switch state {
            case .idle: break
            case .loading(.new):
                self.showLoadingNewState()
                self.state = state
            case .loading(.fresh):
                self.showRefreshingState()
                self.state = state
            case .loading(.more):
                self.showLoadingMoreState()
                self.state = state
            case .loaded(.success):
                self.resetRefreshingView()
                self.resetLoadingStateView()
                self.handleDataUpdate(newState: state)
            case let .loaded(.failure(_, errorMessage)):
                self.showErrorState(with: errorMessage)
                self.state = state
            }
        }
    }

    private func handleDataUpdate(newState: SearchListViewState) {
        let oldRepos = state.viewModel?.repos ?? []
        let newRepos = newState.viewModel?.repos ?? []

        let changes = diff(old: oldRepos, new: newRepos)
        let indexPathes = IndexPathConverter().convert(changes: changes, section: 0)

        // First data load case
        if oldRepos.isEmpty && newRepos.isNotEmpty {
            state = newState
            tableView.reloadData()
            return
        }
        // No canges case
        if changes.isEmpty {
            state = newState
            tableView.reloadData()
            return
        }
        // Refresh data case
        if state.isLoadingRefresh && newState.isLoaded {
            state = newState
            tableView.reloadData()
            return
        }

        state = newState

        if indexPathes.deletes.isNotEmpty {
            tableView.beginUpdates()
            tableView.deleteRows(at: indexPathes.deletes, with: .none)
            tableView.endUpdates()
        }

        if indexPathes.inserts.isNotEmpty {
            tableView.beginUpdates()
            tableView.insertRows(at: indexPathes.inserts, with: .none)
            tableView.endUpdates()
        }

        if indexPathes.replaces.isNotEmpty {
            tableView.reloadData()
        }
    }

    private func showRefreshingState() {
        guard !refreshControl.isRefreshing else { return }
        refreshControl.beginRefreshing()
    }

    private func resetRefreshingView() {
        refreshControl.endRefreshing()
    }

    private func showLoadingNewState() {
        tableView.tableFooterView = loadingLabel
    }

    private func showLoadingMoreState() {
        tableView.tableFooterView = moreActivityIndicatorView
    }

    private func resetLoadingStateView() {
        tableView.tableFooterView = nil
    }


    private func showErrorState(with message: String) {
        errorLabel.text = message
        tableView.tableFooterView = errorLabel
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
    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
    var isLoadingRefresh: Bool {
        if case .loading(.fresh) = self { return true }
        return false
    }
    var isLoaded: Bool {
        if case .loaded = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .loaded(.failure) = self { return true }
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
