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

    static var defaultSearchPaths: [String] {
        var paths: [String] = []
        if let dir = ProcessInfo.processInfo.environment["OPTIMOS_TOOLS_DIR"] { paths.append(dir) }
        if let res = Bundle.main.resourceURL?.appendingPathComponent("tools").path { paths.append(res) }
        paths += ["/opt/homebrew/bin", "/opt/homebrew/opt/libjpeg-turbo/bin", "/usr/local/bin"]
        return paths
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

    func run(_ arguments: [String], input: Data) throws -> Result {
        let process = Process()
        process.executableURL = try locate()
        process.arguments = arguments
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
        process.waitUntilExit()
        group.wait()
        return Result(
            status: process.terminationStatus, output: output.value,
            errorOutput: String(decoding: errors.value, as: UTF8.self))
    }
}
