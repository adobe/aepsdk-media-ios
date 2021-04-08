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

import UIKit
import AEPCore
import AEPIdentity
import AEPAnalytics
import ACPCore
import AEPAssurance
import AEPLifecycle
import AEPMedia

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    private let LAUNCH_ENVIRONMENT_FILE_ID = "94f571f308d5/39273f51e930/launch-00ac4ce72151-development"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        MobileCore.setLogLevel(.trace)
        let appState = application.applicationState;
        
        MobileCore.registerExtensions([Identity.self, Analytics.self, Lifecycle.self, Media.self, AEPAssurance.self], {
            // Use the App id assigned to this application via Adobe Launch
            MobileCore.configureWith(appId: self.LAUNCH_ENVIRONMENT_FILE_ID)
            
            if appState != .background {
                            // only start lifecycle if the application is not in the background
                            MobileCore.lifecycleStart(additionalContextData: ["contextDataKey": "contextDataVal"])
                        }
        })
        
        print("Initialized Media Extension:", Media.extensionVersion + " core:", MobileCore.extensionVersion + " analyticsExt:", Analytics.extensionVersion + " IdentityExt:", Identity.extensionVersion + " LifecycleExt:", Lifecycle.extensionVersion + " AssuranceExt:", AEPAssurance.extensionVersion)

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
}

