//
//  DataRequest+Extension.swift
//  GithubRepoSearch
//
//  Created by Serhii Onopriienko on 5/18/19.
//  Copyright © 2019 Serhii Onopriienko. All rights reserved.
//

import Foundation
import Alamofire

extension DataRequest {
    func logRequest() -> Self {
        debugPrint(self)
        return self
    }
}
