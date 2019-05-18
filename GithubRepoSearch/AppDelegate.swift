//
//  AppDelegate.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        let mainScene = SearchConfigurator.scene()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = mainScene
        window?.makeKeyAndVisible()

        return true
    }
}

