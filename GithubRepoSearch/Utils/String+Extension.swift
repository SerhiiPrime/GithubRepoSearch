//
//  String+Extension.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/19/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation

extension String {

    func trunc(length: Int, trailing: String = "") -> String {
        let finalLength = length - trailing.count
        return (self.count > finalLength) ? self.prefix(finalLength) + trailing : self
    }
}
