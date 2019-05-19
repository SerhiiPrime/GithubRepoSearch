//
//  BrowserViewController.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/19/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import UIKit
import WebKit

class BrowserViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    private var repoUrl: URL?

    static func scene(with repoUrl: URL) -> BrowserViewController {
        let viewController = BrowserViewController(nibName: "BrowserViewController", bundle: nil)
        viewController.repoUrl = repoUrl
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if let url = repoUrl {
            webView.load(URLRequest(url: url))
        }
    }

    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true)
    }

}
