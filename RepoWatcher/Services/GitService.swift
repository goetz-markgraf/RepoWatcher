import Foundation

class GitService {
    let repositoryPath: String

    init(repositoryPath: String) {
        self.repositoryPath = repositoryPath
    }

    func checkStatus(completion: @escaping (GitStatus) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }

            print("🔍 Checking status for repository: \(self.repositoryPath)")

            let status: GitStatus

            // 1. Check upstream
            let upstreamResult = self.runGitCommand(["rev-parse", "--abbrev-ref", "@{u}"])
            print("🔍 Upstream check: \(upstreamResult ?? "nil (no upstream)")")
            if upstreamResult == nil {
                status = .noUpstream
            }
            // 2. Check uncommitted changes
            else if let porcelain = self.runGitCommand(["status", "--porcelain"]),
                    !porcelain.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("🔍 Uncommitted changes detected: \(porcelain.prefix(100))")
                status = .uncommitted
            }
            // 3. Check unpushed commits
            else if let unpushed = self.runGitCommand(["log", "@{u}..HEAD", "--oneline"]),
                    !unpushed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("🔍 Unpushed commits detected: \(unpushed.prefix(100))")
                status = .unpushed
            }
            // 4. Check unpulled commits
            else if let unpulled = self.runGitCommand(["log", "HEAD..@{u}", "--oneline"]),
                    !unpulled.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("🔍 Unpulled commits detected: \(unpulled.prefix(100))")
                status = .unpulled
            }
            // 5. All clean
            else {
                print("🔍 Repository is clean")
                status = .clean
            }

            print("✅ Final status: \(status)")

            DispatchQueue.main.async {
                completion(status)
            }
        }
    }

    func fetch(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global().async { [weak self] in
            guard let self = self else {
                DispatchQueue.main.async {
                    completion(false)
                }
                return
            }

            let success = self.runGitCommand(["fetch"]) != nil

            DispatchQueue.main.async {
                completion(success)
            }
        }
    }

    private func runGitCommand(_ args: [String]) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/git")
        process.arguments = args
        process.currentDirectoryURL = URL(fileURLWithPath: repositoryPath)

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        do {
            try process.run()
            process.waitUntilExit()

            let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
            let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

            if let errorOutput = String(data: errorData, encoding: .utf8), !errorOutput.isEmpty {
                print("⚠️ Git command error for 'git \(args.joined(separator: " "))': \(errorOutput)")
            }

            guard process.terminationStatus == 0 else {
                print("❌ Git command failed with status \(process.terminationStatus): git \(args.joined(separator: " "))")
                return nil
            }

            return String(data: outputData, encoding: .utf8)
        } catch {
            print("❌ Failed to run git command: \(error.localizedDescription)")
            return nil
        }
    }
}
