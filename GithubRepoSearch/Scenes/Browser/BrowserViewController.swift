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
    
    private var repoUrl: URL?
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
    
    static func scene(with repoUrl: URL) -> BrowserViewController {
        let viewController = BrowserViewController(nibName: "BrowserViewController", bundle: nil)
        viewController.repoUrl = repoUrl
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(closeAction))
        view.addGestureRecognizer(tapGesture)

        webView.navigationDelegate = self

        if let url = repoUrl {
            webView.load(URLRequest(url: url))
            activityIndicator.startAnimating()
        }
    }

    @IBAction func closeAction(_ sender: UIButton) {
        dismiss(animated: true)
    }
}

extension BrowserViewController: WKNavigationDelegate {

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activityIndicator.stopAnimating()
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        activityIndicator.stopAnimating()
    }
}
