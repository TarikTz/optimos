import Foundation

public protocol Codec: Sendable {
    var format: ImageFormat { get }
    func decode(_ data: Data) throws -> ImageData
    func encode(_ image: ImageData, options: EncodeOptions) throws -> Data
}
