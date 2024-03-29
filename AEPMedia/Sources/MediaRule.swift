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
    typealias RuleFn = (MediaRule, [String: Any]) -> Bool
    let name: Int
    let description: String
    var predicateList: [(fn: RuleFn, expectedResult: Bool, errorMsg: String)] = []
    var actionList: [(MediaRule, [String: Any]) -> Bool] = []

    init(name: Int, description: String) {
        self.name = name
        self.description = description
    }

    @discardableResult
    func addPredicate(predicateFn: @escaping RuleFn, expectedValue: Bool, errorMsg: String) -> MediaRule {
        let predicateTuple = (predicateFn, expectedValue, errorMsg)
        predicateList.append(predicateTuple)

        return self
    }

    @discardableResult
    func addAction(actionFn: @escaping RuleFn) -> MediaRule {
        actionList.append(actionFn)

        return self
    }

    func runPredicates(context: [String: Any]) -> (Bool, String) {
        for predicate in predicateList {
            let predicateFn = predicate.fn
            let expectedValue = predicate.expectedResult

            if predicateFn(self, context) != expectedValue {
                return (false, predicate.errorMsg)
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
