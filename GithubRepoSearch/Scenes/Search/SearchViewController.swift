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

enum SearchListViewState: Equatable {
    case idle
    case loading(Loading)
    case loaded(Result)

    enum Loading: Equatable {
        case new
        case fresh(prevModel: ViewModel?)
        case more(prevModel: ViewModel)
    }

    enum Result: Equatable {
        case success(ViewModel)
        case failure(prev: ViewModel?, String)
    }

    struct ViewModel: Equatable {
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
        label.frame = view.bounds
        label.center = view.center
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
        label.frame = view.bounds
        label.center = view.center
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
        tableView.estimatedRowHeight = LocalConstants.cellHeight
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
        guard state != self.state else { return }
        DispatchQueue.main.async {
            switch state {
            case .idle:
                self.state = state
                self.tableView.reloadData()
                self.resetLoadingState()
            case .loading(.new):
                self.state = state
                self.showLoadingNewState()
            case .loading(.fresh):
                self.state = state
                self.showRefreshingState()
            case .loading(.more):
                self.state = state
                self.showLoadingMoreState()
            case .loaded(.success):
                self.handleDataUpdate(newState: state)
                self.resetLoadingState()
            case let .loaded(.failure(_, errorMessage)):
                self.state = state
                self.tableView.reloadData()
                self.showErrorState(with: errorMessage)
            }
        }
    }

    private func handleDataUpdate(newState: SearchListViewState) {
        // Refresh data case
        if state.isLoadingRefresh && newState.isLoaded {
            state = newState
            tableView.reloadData()
            return
        }

        let oldRepos = state.viewModel?.repos ?? []
        let newRepos = newState.viewModel?.repos ?? []

        let changes = diff(old: oldRepos, new: newRepos)
        let indexPathes = IndexPathConverter().convert(changes: changes, section: 0)

        // No canges and First data load case
        if changes.isEmpty || (oldRepos.isEmpty && newRepos.isNotEmpty) {
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

    private func showLoadingNewState() {
        resetLoadingState()
        view.addSubview(loadingLabel)
    }

    private func showLoadingMoreState() {
        tableView.tableFooterView = moreActivityIndicatorView
    }

    private func showErrorState(with message: String) {
        resetLoadingState()
        errorLabel.text = message
        view.addSubview(errorLabel)
    }

    private func resetLoadingState() {
        tableView.tableFooterView = nil
        loadingLabel.removeFromSuperview()
        errorLabel.removeFromSuperview()
        refreshControl.endRefreshing()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return state.viewModel?.repos.count ?? 0
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
