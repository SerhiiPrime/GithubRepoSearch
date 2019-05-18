//
//  SearchViewController.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import UIKit

// MARK: - Protocols

protocol SearchViewControllerInput {

}

protocol SearchViewControllerOutput {
    func setup()
}

// MARK: - Implementation

final class SearchViewController: UIViewController {
    var output: SearchViewControllerOutput?

    override func viewDidLoad() {
        super.viewDidLoad()

        output?.setup()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // Dispose of any resources that can be recreated.
    }
}

extension SearchViewController: SearchViewControllerInput {

}
