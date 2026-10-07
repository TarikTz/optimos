import Foundation

/// Keeps copies of files before they are overwritten so a session can be undone or re-run from the
/// originals. Backups live in a temporary folder until `deleteAll()`.
public final class BackupStore: @unchecked Sendable {
    private let directory: URL
    private let lock = NSLock()
    private var backups: [(original: URL, copy: URL)] = []
    private var created: [URL] = []
    private var isClosed = false

    public init(directory: URL = FileManager.default.temporaryDirectory
        .appendingPathComponent("OptimosBackups-\(UUID().uuidString)", isDirectory: true)
    ) {
        self.directory = directory
    }

    /// Copies `url` aside. Only the first call per file keeps a copy, so the backup is always the original.
    public func backUp(_ url: URL) throws {
        lock.lock()
        defer { lock.unlock() }
        // After the session ended no new backup may appear (a late job would leave an orphan folder);
        // the caller's willReplace then throws and the file is left untouched.
        guard !isClosed else { throw CocoaError(.userCancelled) }
        let key = url.standardizedFileURL.path
        guard !backups.contains(where: { $0.original.standardizedFileURL.path == key }) else { return }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let copy = directory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.copyItem(at: url, to: copy)
        backups.append((url, copy))
    }

    /// Remembers a file the session created by converting, so a restore can remove it.
    public func recordCreated(_ url: URL) {
        lock.lock()
        defer { lock.unlock() }
        created.append(url)
    }

    /// Puts every original back and removes the converted files. One failure never stops the rest.
    /// - Returns: the files that could not be restored.
    @discardableResult
    public func restoreAll() -> [URL] {
        lock.lock()
        defer { lock.unlock() }
        var failed: [URL] = []
        for (original, copy) in backups {
            do {
                let temp = original.deletingLastPathComponent().appendingPathComponent(".optimos-\(UUID().uuidString).tmp")
                try FileManager.default.copyItem(at: copy, to: temp)
                _ = try FileManager.default.replaceItemAt(original, withItemAt: temp)
            } catch {
                failed.append(original)
            }
        }
        for url in created { try? FileManager.default.removeItem(at: url) }
        created = []
        return failed
    }

    /// Deletes the backups (call when the session ends).
    public func deleteAll() {
        lock.lock()
        defer { lock.unlock() }
        isClosed = true
        try? FileManager.default.removeItem(at: directory)
        backups = []
        created = []
    }
}
