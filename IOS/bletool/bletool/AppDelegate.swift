// Author: Fan Gaoyige
// Date: 31/03/2022
// E-mail: fangaoyige@live.com
// Lab: NUS Lab of Sensor, MEMS and NMES

import UIKit
import Firebase

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        // Override point for customization after application launch.
        return true
    }

}

