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
    let stars: String
}

class RepoTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var starsLabel: UILabel!

    @discardableResult
    func setup(with viewModel: RepoViewModel) -> RepoTableViewCell {
        nameLabel.text = viewModel.name
        urlLabel.text = viewModel.urlLabel
        starsLabel.text = viewModel.stars
        return self
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        urlLabel.text = nil
        starsLabel.text = nil
    }
}
