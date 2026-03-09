import Foundation

class ConfigService {
    static let shared = ConfigService()

    private let configPath = "~/.config/repowatcher/config.json"

    private init() {}

    func loadConfig() -> Config {
        let expandedPath = NSString(string: configPath).expandingTildeInPath
        let fileManager = FileManager.default

        // Check if config file exists
        guard fileManager.fileExists(atPath: expandedPath) else {
            // Return default config if file doesn't exist
            return Config(repositoryPath: "~/config-files")
        }

        do {
            // Read and decode config file
            let data = try Data(contentsOf: URL(fileURLWithPath: expandedPath))
            let decoder = JSONDecoder()
            let config = try decoder.decode(Config.self, from: data)
            return config
        } catch {
            // Return default config if there's an error reading or decoding
            print("Error loading config: \(error.localizedDescription)")
            return Config(repositoryPath: "~/config-files")
        }
    }

    func saveConfig(_ config: Config) {
        let expandedPath = NSString(string: configPath).expandingTildeInPath
        let fileManager = FileManager.default

        do {
            // Ensure directory exists
            let directoryPath = NSString(string: expandedPath).deletingLastPathComponent
            if !fileManager.fileExists(atPath: directoryPath) {
                try fileManager.createDirectory(atPath: directoryPath, withIntermediateDirectories: true, attributes: nil)
            }

            // Encode and write config to file
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(config)
            try data.write(to: URL(fileURLWithPath: expandedPath))
        } catch {
            print("Error saving config: \(error.localizedDescription)")
        }
    }
}
