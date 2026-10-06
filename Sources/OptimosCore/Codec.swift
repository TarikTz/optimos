import Foundation

public protocol Codec: Sendable {
    var format: ImageFormat { get }
    func decode(_ data: Data) throws -> ImageData
    func encode(_ image: ImageData, options: EncodeOptions) throws -> Data
}

public enum Codecs {
    public static func codec(for format: ImageFormat) -> any Codec {
        switch format {
        case .png: PNGCodec()
        case .jpeg: JPEGCodec()
        case .webp: WebPCodec()
        }
    }
}
