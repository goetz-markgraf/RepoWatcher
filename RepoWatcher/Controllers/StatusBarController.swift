import AppKit
import Foundation

class StatusBarController {
    var statusItem: NSStatusItem?
    var gitService: GitService
    var timer: Timer?
    let fetchInterval: TimeInterval = 300.0 // 5 Minuten
    let repositoryPath: String

    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
        self.gitService = GitService(repositoryPath: repositoryPath)
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

        // Update now action
        let updateItem = NSMenuItem(title: "Jetzt aktualisieren", action: #selector(updateNow), keyEquivalent: "r")
        updateItem.target = self
        menu.addItem(updateItem)

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
        // Initial update
        updateStatus()

        // Start periodic timer
        timer = Timer.scheduledTimer(
            timeInterval: fetchInterval,
            target: self,
            selector: #selector(timerTick),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func timerTick() {
        // Perform git fetch
        gitService.fetch { success in
            // Update status after fetch completes
            self.updateStatus()
        }
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
