import Foundation
import Observation
import OptimosCore

struct OptimizerRow: Identifiable, Equatable {
    enum Status: Equatable {
        case queued
        case working
        case done(FileJobResult)
        case failed(String)
        case restored
    }

    let id = UUID()
    let url: URL
    var status: Status = .queued
}

/// One optimizer-window session: the rows, the settings, and the work queue. Closing the window
/// ends the session (`close()` deletes the backups).
@MainActor
@Observable
final class OptimizerViewModel {
    private static let settingsKey = "optimizerSettings"
    private static let concurrency = 3

    private(set) var rows: [OptimizerRow] = []
    var settings: OptimizeSettings {
        didSet { Self.save(settings, to: defaults) }
    }
    private(set) var isWorking = false

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let backups: BackupStore
    @ObservationIgnored private var runTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard, backups: BackupStore = BackupStore()) {
        self.defaults = defaults
        self.backups = backups
        self.settings =
            defaults.data(forKey: Self.settingsKey).flatMap { try? JSONDecoder().decode(OptimizeSettings.self, from: $0) }
            ?? OptimizeSettings()
    }

    var canUndo: Bool {
        !isWorking && rows.contains {
            if case .done(let result) = $0.status, result.outcome != .alreadyOptimal { return true }
            return false
        }
    }

    var canRunAgain: Bool { !isWorking && !rows.isEmpty }

    /// Adds files (folders are searched) that are not already listed, and starts processing them.
    func add(_ urls: [URL]) {
        let known = Set(rows.map { $0.url.standardizedFileURL.path })
        let fresh = ImageFileScanner.imageURLs(from: urls).filter { !known.contains($0.standardizedFileURL.path) }
        guard !fresh.isEmpty else { return }
        let added = fresh.map { OptimizerRow(url: $0) }
        rows.append(contentsOf: added)
        start(added.map(\.id))
    }

    /// Puts the originals back and runs every file again with the current settings, so lossy quality never stacks.
    func runAgain() {
        guard canRunAgain else { return }
        backups.restoreAll()
        for index in rows.indices { rows[index].status = .queued }
        start(rows.map(\.id))
    }

    func undo() {
        guard canUndo else { return }
        let failed = Set(backups.restoreAll().map { $0.standardizedFileURL.path })
        for index in rows.indices {
            if case .done(let result) = rows[index].status, result.outcome != .alreadyOptimal {
                rows[index].status =
                    failed.contains(rows[index].url.standardizedFileURL.path)
                    ? .failed("could not restore the original") : .restored
            }
        }
    }

    /// Ends the session: stops queued work and deletes the backups.
    func close() {
        runTask?.cancel()
        backups.deleteAll()
    }

    private func start(_ ids: [UUID]) {
        let previous = runTask
        isWorking = true
        runTask = Task {
            await previous?.value
            await withTaskGroup(of: Void.self) { group in
                var iterator = ids.makeIterator()
                var running = 0
                while running < Self.concurrency, let id = iterator.next() {
                    group.addTask { await self.process(id) }
                    running += 1
                }
                while await group.next() != nil {
                    if let id = iterator.next() { group.addTask { await self.process(id) } }
                }
            }
            isWorking = false
        }
    }

    private func process(_ id: UUID) async {
        guard !Task.isCancelled, let index = rows.firstIndex(where: { $0.id == id }) else { return }
        let url = rows[index].url
        let settings = self.settings
        let backups = self.backups
        rows[index].status = .working
        let status: OptimizerRow.Status
        do {
            let result = try await FileJob.run(url, settings: settings, willReplace: { try backups.backUp($0) })
            if case .converted(let output) = result.outcome { backups.recordCreated(output) }
            status = .done(result)
        } catch {
            status = .failed(ErrorMessage.text(for: error))
        }
        if let current = rows.firstIndex(where: { $0.id == id }) { rows[current].status = status }
    }

    private static func save(_ settings: OptimizeSettings, to defaults: UserDefaults) {
        if let data = try? JSONEncoder().encode(settings) { defaults.set(data, forKey: settingsKey) }
    }
}
