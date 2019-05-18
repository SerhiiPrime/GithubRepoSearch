//
//  RepoTableViewCell.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import UIKit

struct RepoViewModel {
    let name: String
    let urlLabel: String
}

class RepoTableViewCell: UITableViewCell {
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var urlLabel: UILabel!

    @discardableResult
    func setup(with viewModel: RepoViewModel) -> RepoTableViewCell {
        nameLabel.text = viewModel.name
        urlLabel.text = viewModel.urlLabel
        return self
    }
}
