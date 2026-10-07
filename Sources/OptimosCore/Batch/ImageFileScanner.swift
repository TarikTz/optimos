import Foundation

public enum ImageFileScanner {
    static let supportedExtensions: Set<String> = ["png", "jpg", "jpeg", "webp"]

    /// Files you named are returned as they are (an unsupported one fails later with a clear message).
    /// Folders are searched, keeping only supported images and skipping hidden files. No duplicates.
    public static func imageURLs(from urls: [URL]) -> [URL] {
        var seen = Set<String>()
        var result: [URL] = []
        func add(_ url: URL) {
            if seen.insert(url.standardizedFileURL.path).inserted { result.append(url) }
        }
        for url in urls {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else { continue }
            guard isDirectory.boolValue else {
                add(url)
                continue
            }
            let walker = FileManager.default.enumerator(
                at: url, includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants])
            let found = (walker?.allObjects as? [URL] ?? [])
                .filter { supportedExtensions.contains($0.pathExtension.lowercased()) }
                .filter { (try? $0.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true }
                .sorted { $0.path < $1.path }
            found.forEach(add)
        }
        return result
    }
}
