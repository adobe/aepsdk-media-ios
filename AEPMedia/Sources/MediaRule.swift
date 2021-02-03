/*
 Copyright 2021 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0
 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

import Foundation

class MediaRule {
    let name: Int
    let description: String
    var predicateList: [((MediaRule, [String: Any]) -> Bool, Bool, String)] = []
    var actionList: [(MediaRule, [String: Any]) -> Bool] = []

    init(name: Int, description: String) {
        self.name = name
        self.description = description
    }

    func addPredicate(predicateFn: @escaping (MediaRule, [String: Any]) -> Bool, expectedValue: Bool, errorMsg: String) {
        let predicateTuple = (predicateFn, expectedValue, errorMsg)
        predicateList.append(predicateTuple)
    }

    func addAction(actionFn: @escaping (MediaRule, [String: Any]) -> Bool) {
        actionList.append(actionFn)
    }

    func runPredicates(context: [String: Any]) -> (Bool, String) {
        for predicate in predicateList {
            let predicateFn = predicate.0
            let expectedValue = predicate.1

            if predicateFn(self, context) != expectedValue {
                return (false, predicate.2)
            }
        }
        return (true, "")
    }

    func runActions(context: [String: Any]) -> Bool {
        for action in actionList {
            let ret = action(self, context)

            if !ret {
                return false
            }
        }
        return true
    }
}
