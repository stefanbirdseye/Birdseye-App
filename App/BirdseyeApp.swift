import SwiftUI
import UIKit

@main
struct BirdseyeApp: App {

    init() {
        UIRefreshControl.appearance().tintColor = UIColor(.gray)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
