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
}

// MARK: - Implementation

final class SearchViewController: UIViewController {
    var output: SearchViewControllerOutput?

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

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

//        tableView.delegate = self
//        tableView.dataSource = self
//        //tableView.register(<#T##cellClass: AnyClass?##AnyClass?#>, forCellReuseIdentifier: <#T##String#>)
    }
}

extension SearchViewController: SearchViewControllerInput {

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
