public enum OptimosError: Error, Equatable, CustomStringConvertible {
    case unsupportedFormat
    case decodeFailed(String)
    case encodeFailed(String)
    case alphaNotSupported(ImageFormat)
    case invalidOptions(String)
    case toolMissing(String)
    case cancelled
    case imageTooLarge(width: Int, height: Int)

    public var description: String {
        switch self {
        case .unsupportedFormat: "unsupported or unrecognised image format"
        case .decodeFailed(let why): "could not decode image: \(why)"
        case .encodeFailed(let why): "could not encode image: \(why)"
        case .alphaNotSupported(let format):
            "image has transparency, which \(format.rawValue) cannot store (supply a background colour)"
        case .invalidOptions(let why): "invalid options: \(why)"
        case .toolMissing(let name): "required tool '\(name)' was not found (see README for install steps)"
        case .cancelled: "cancelled"
        case .imageTooLarge(let width, let height):
            "image is too large (\(width) × \(height) pixels); the limit is \(ImageLimits.maxPixels / 1_000_000) megapixels and \(ImageLimits.maxSide) pixels on a side"
        }
    }
}
