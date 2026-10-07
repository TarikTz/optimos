import Foundation

private final class Box<T>: @unchecked Sendable {
    var value: T
    init(_ value: T) { self.value = value }
}

struct ExternalTool: Sendable {
    let name: String
    let searchPaths: [String]

    init(name: String, searchPaths: [String] = ExternalTool.defaultSearchPaths) {
        self.name = name
        self.searchPaths = searchPaths
    }

    /// Inside the app the bundled tools come first and the environment variable is ignored, so
    /// nothing launching the app can swap in its own tools (they would inherit its permissions).
    /// Outside an app bundle (the CLI, tests, a debug build) the variable and Homebrew are honoured.
    static var defaultSearchPaths: [String] {
        let bundled = Bundle.main.resourceURL?.appendingPathComponent("tools").path
        if Bundle.main.bundlePath.hasSuffix(".app"), let bundled,
            FileManager.default.fileExists(atPath: bundled)
        {
            return [bundled]
        }
        var paths: [String] = []
        if !Bundle.main.bundlePath.hasSuffix(".app"),
            let dir = toolsDirectory(from: ProcessInfo.processInfo.environment)
        {
            paths.append(dir)
        }
        if let bundled { paths.append(bundled) }
        paths += ["/opt/homebrew/bin", "/opt/homebrew/opt/jpeg-turbo/bin", "/opt/homebrew/opt/libjpeg-turbo/bin"]
        return paths
    }

    /// Tools get a clean environment: no inherited DYLD_* variables or other surprises.
    static let cleanEnvironment = ["PATH": "/usr/bin:/bin", "LC_ALL": "C"]

    /// A tool that runs longer than this is stopped (a corrupt image can make one spin).
    static let defaultTimeout: TimeInterval = 120

    /// OPTIMOS_TOOLS_DIR, ignored unless it is an absolute path (empty or relative would mean the cwd).
    static func toolsDirectory(from environment: [String: String]) -> String? {
        guard let dir = environment["OPTIMOS_TOOLS_DIR"], dir.hasPrefix("/") else { return nil }
        return dir
    }

    struct Result {
        let status: Int32
        let output: Data
        let errorOutput: String
    }

    func locate() throws -> URL {
        for dir in searchPaths {
            let url = URL(fileURLWithPath: dir).appendingPathComponent(name)
            if FileManager.default.isExecutableFile(atPath: url.path) { return url }
        }
        throw OptimosError.toolMissing(name)
    }

    func run(_ arguments: [String], input: Data, timeout: TimeInterval = ExternalTool.defaultTimeout) throws -> Result {
        let process = Process()
        process.executableURL = try locate()
        process.arguments = arguments
        process.environment = Self.cleanEnvironment
        let stdin = Pipe(), stdout = Pipe(), stderr = Pipe()
        // Per-fd (not process-wide): a tool that exits early yields EPIPE instead of SIGPIPE.
        _ = fcntl(stdin.fileHandleForWriting.fileDescriptor, F_SETNOSIGPIPE, 1)
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr
        try process.run()

        // The pumps get dedicated threads, not GCD's global queue: callers block a cooperative
        // thread in here, and once every one of those is blocked the global queue gets no worker,
        // the tools wait on stdin forever, and the whole process deadlocks.
        let output = Box(Data()), errors = Box(Data())
        let group = DispatchGroup()
        group.enter()
        Thread.detachNewThread {
            output.value = stdout.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        group.enter()
        Thread.detachNewThread {
            errors.value = stderr.fileHandleForReading.readDataToEndOfFile()
            group.leave()
        }
        // Write on its own thread so a full stdout pipe cannot deadlock us.
        Thread.detachNewThread {
            try? stdin.fileHandleForWriting.write(contentsOf: input)
            try? stdin.fileHandleForWriting.close()
        }
        // Poll instead of blocking so cancelling the calling task, or a hung tool, can stop the process.
        let started = Date()
        var stopped: OptimosError?
        while process.isRunning {
            if Task.isCancelled {
                stopped = .cancelled
            } else if Date().timeIntervalSince(started) > timeout {
                stopped = .encodeFailed("\(name) timed out after \(Int(timeout)) seconds")
            }
            if stopped != nil {
                process.terminate()
                break
            }
            usleep(20_000)
        }
        process.waitUntilExit()
        group.wait()
        if let stopped { throw stopped }
        return Result(
            status: process.terminationStatus, output: output.value,
            errorOutput: String(decoding: errors.value, as: UTF8.self))
    }
}
