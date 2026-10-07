import Foundation
import Testing

@testable import OptimosApp

@Suite struct SaveLocationStoreTests {
    /// An isolated preferences domain so tests never touch the user's real settings.
    private func makeStore() -> (SaveLocationStore, cleanup: () -> Void) {
        let name = "optimos-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        return (SaveLocationStore(defaults: defaults), { defaults.removePersistentDomain(forName: name) })
    }

    @Test func defaultsToPicturesOptimos() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        #expect(store.directory == SaveLocationStore.defaultDirectory)
        #expect(store.directory.lastPathComponent == "Optimos")
        #expect(store.directory.deletingLastPathComponent().lastPathComponent == "Pictures")
    }

    @Test func remembersTheChosenFolder() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        let chosen = URL(fileURLWithPath: "/tmp/optimos-shots", isDirectory: true)
        store.setDirectory(chosen)
        #expect(store.directory.path == "/tmp/optimos-shots")
    }

    @Test func aRememberedFolderThatNoLongerExistsIsStillReturned() {
        // Saving then reports a clear error; the default is never substituted silently.
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        store.setDirectory(URL(fileURLWithPath: "/definitely/not/a/real/folder", isDirectory: true))
        #expect(store.directory.path == "/definitely/not/a/real/folder")
    }

    @Test func remembersTheLastSavedFile() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        #expect(store.lastSavedFile == nil)
        store.setLastSavedFile(URL(fileURLWithPath: "/tmp/a.png"))
        #expect(store.lastSavedFile?.path == "/tmp/a.png")
    }

    @Test func displayPathAbbreviatesTheHomeFolder() {
        let (store, cleanup) = makeStore()
        defer { cleanup() }
        #expect(store.displayPath.hasPrefix("~/"))
    }
}

@Suite struct AskWhereToSaveTests {
    @Test func asksByDefaultAndRemembersTheToggle() {
        let name = "optimos-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let store = SaveLocationStore(defaults: defaults)
        #expect(store.asksWhereToSave)
        store.setAsksWhereToSave(false)
        #expect(!store.asksWhereToSave)
    }
}
