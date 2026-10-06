import Foundation

public enum ImageFormat: String, Codable, Sendable, CaseIterable {
    case png, jpeg, webp

    public var fileExtension: String { self == .jpeg ? "jpg" : rawValue }

    /// Accepts "png", "jpg", "jpeg", "webp" (case-insensitive).
    public init?(name: String) {
        switch name.lowercased() {
        case "png": self = .png
        case "jpg", "jpeg": self = .jpeg
        case "webp": self = .webp
        default: return nil
        }
    }

    public static func sniff(_ data: Data) -> ImageFormat? {
        let b = [UInt8](data.prefix(12))
        if b.count >= 8, Array(b[0..<8]) == [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] { return .png }
        if b.count >= 3, b[0] == 0xFF, b[1] == 0xD8, b[2] == 0xFF { return .jpeg }
        if b.count >= 12, Array(b[0..<4]) == Array("RIFF".utf8), Array(b[8..<12]) == Array("WEBP".utf8) {
            return .webp
        }
        return nil
    }
}
