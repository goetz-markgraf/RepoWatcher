import AppKit
import Foundation

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 1. Load configuration
        let config = ConfigService.shared.loadConfig()

        // 2. Expand tilde in repository path
        let repositoryPath = NSString(string: config.repositoryPath).expandingTildeInPath

        // 3. Create StatusBarController with the path
        statusBarController = StatusBarController(repositoryPath: repositoryPath)

        // 4. Setup status bar
        statusBarController?.setupStatusBar()

        // 5. Initial status update
        statusBarController?.updateStatus()

        // 6. Start timer
        statusBarController?.startTimer()
    }
}
