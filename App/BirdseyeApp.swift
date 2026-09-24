import SwiftUI
import UIKit
import TipKit

@main
struct BirdseyeApp: App {

    init() {
        UIRefreshControl.appearance().tintColor = UIColor(.gray)
        try? Tips.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
