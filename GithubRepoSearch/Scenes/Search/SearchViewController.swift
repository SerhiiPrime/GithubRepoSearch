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

}

protocol SearchViewControllerOutput {
    func setup()
    func search(query: String)
    func cancelSearch()
    func loadMore()
    func refresh()
    func showRepo(at index: Int)
}

// MARK: - Implementation

final class SearchViewController: UIViewController {
    var output: SearchViewControllerOutput?

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

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

}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return LocalConstants.cellHeight
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }

    private func shouldStartLoadingMore(atIndexPath indexPath: IndexPath, whenScrolledThroughNumberOfProfiles reposNumber: Int) -> Bool {
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
