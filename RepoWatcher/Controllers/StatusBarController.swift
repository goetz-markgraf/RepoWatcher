import AppKit
import Foundation

class StatusBarController {
    var statusItem: NSStatusItem?
    var gitService: GitService
    var timer: Timer?
    let checkInterval: TimeInterval = 300.0 // 5 Minuten
    let repositoryPath: String
    var isValidRepository: Bool = false

    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self.gitService = GitService(repositoryPath: repositoryPath)
        self.isValidRepository = validateRepository(at: repositoryPath)
    }

    private func validateRepository(at path: String) -> Bool {
        let fileManager = FileManager.default

        // Check if path is home directory
        let homeDir = NSString(string: "~").expandingTildeInPath
        if path == homeDir {
            print("⚠️ Repository path is home directory, this is not recommended")
            return false
        }

        // Check if path exists and is a directory
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory), isDirectory.boolValue else {
            print("⚠️ Repository path does not exist or is not a directory: \(path)")
            return false
        }

        // Check if it's a git repository
        let gitPath = (path as NSString).appendingPathComponent(".git")
        guard fileManager.fileExists(atPath: gitPath) else {
            print("⚠️ Path is not a git repository (no .git folder): \(path)")
            return false
        }

        print("✅ Repository is valid: \(path)")
        return true
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Repository Status")
            image?.isTemplate = true
            button.image = image
        }

        let menu = NSMenu()

        // Repository path (disabled, not clickable)
        let pathItem = NSMenuItem(title: "Repository: \(repositoryPath)", action: nil, keyEquivalent: "")
        pathItem.isEnabled = false
        menu.addItem(pathItem)

        menu.addItem(NSMenuItem.separator())

        // Show update action or error message based on repository validity
        if isValidRepository {
            let updateItem = NSMenuItem(title: "Jetzt aktualisieren", action: #selector(updateNow), keyEquivalent: "r")
            updateItem.target = self
            menu.addItem(updateItem)
        } else {
            let errorItem = NSMenuItem(title: "⚠️ Kein gültiges Git-Repository", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    func updateStatus() {
        print("📱 updateStatus() called")
        gitService.checkStatus { status in
            print("📱 Received status: \(status), color: \(status.color?.description ?? "nil")")
            DispatchQueue.main.async {
                if let button = self.statusItem?.button {
                    // Create image with color configuration
                    if let color = status.color {
                        // For colored status: create colored SF Symbol
                        let config = NSImage.SymbolConfiguration(pointSize: 12, weight: .regular)
                            .applying(.init(paletteColors: [color]))
                        let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Repository Status")
                        button.image = image?.withSymbolConfiguration(config)
                        print("📱 Set colored image with color: \(color)")
                    } else {
                        // For clean status: use default template
                        let image = NSImage(systemSymbolName: "circle.fill", accessibilityDescription: "Repository Status")
                        image?.isTemplate = true
                        button.image = image
                        print("📱 Set template image (default color)")
                    }
                } else {
                    print("❌ No button available!")
                }
            }
        }
    }

    func startTimer() {
        // Only start timer if repository is valid
        guard isValidRepository else {
            print("⚠️ Skipping timer start - invalid repository")
            return
        }

        // Initial fetch and update
        gitService.fetch { success in
            print("✅ Initial fetch completed: \(success)")
            self.updateStatus()
        }

        // Start periodic timer for status checks
        timer = Timer.scheduledTimer(
            timeInterval: checkInterval,
            target: self,
            selector: #selector(timerTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func timerTick() {
        // Periodic status check (uses lightweight ls-remote)
        updateStatus()
    }

    @objc func updateNow() {
        // Perform git fetch and update status immediately
        gitService.fetch { success in
            self.updateStatus()
        }
    }

    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
