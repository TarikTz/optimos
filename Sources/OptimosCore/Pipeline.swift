import Foundation

public struct OutputSpec: Sendable, Equatable {
    /// nil keeps the input format.
    public var format: ImageFormat?
    public var options: EncodeOptions
    public init(format: ImageFormat? = nil, options: EncodeOptions = EncodeOptions()) {
        self.format = format
        self.options = options
    }
}

public struct ProcessedImage: Sendable {
    public let bytes: Data
    public let format: ImageFormat
    public let originalSize: Int
    public let newSize: Int
    public var savedBytes: Int { max(0, originalSize - newSize) }
    public var savedFraction: Double {
        originalSize == 0 ? 0 : Double(savedBytes) / Double(originalSize)
    }
}

public struct Pipeline: Sendable {
    public var operations: [any Operation]
    public var output: OutputSpec

    public init(operations: [any Operation] = [], output: OutputSpec = OutputSpec()) {
        self.operations = operations
        self.output = output
    }

    /// Lossless, same format, metadata stripped.
    public static var defaultOptimize: Pipeline {
        Pipeline(operations: [StripMetadata(), Optimize()])
    }

    /// Runs off the caller's executor. Cancelling the calling task stops work between steps.
    public func run(_ input: Data) async throws -> ProcessedImage {
        let task = Task.detached(priority: .userInitiated) { try self.runSync(input) }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    func runSync(_ input: Data) throws -> ProcessedImage {
        if let q = output.options.quality, !(1...100).contains(q) {
            throw OptimosError.invalidOptions("quality must be between 1 and 100")
        }
        guard let inFormat = ImageFormat.sniff(input) else { throw OptimosError.unsupportedFormat }
        try ImageLimits.check(input)
        try checkCancelled()
        var image = try Codecs.codec(for: inFormat).decode(input)
        for operation in operations {
            try checkCancelled()
            image = try operation.apply(image)
        }
        try checkCancelled()
        let outFormat = output.format ?? inFormat
        let bytes = try Codecs.codec(for: outFormat).encode(image, options: output.options)

        // Never-larger guardrail: only for a plain same-format optimize (no resize).
        if outFormat == inFormat, !image.pixelsModified, bytes.count >= input.count {
            let fallback = image.stripMetadata ? try losslesslyStripped(input, image: image) : input
            return ProcessedImage(
                bytes: fallback, format: inFormat, originalSize: input.count, newSize: fallback.count)
        }
        return ProcessedImage(bytes: bytes, format: outFormat, originalSize: input.count, newSize: bytes.count)
    }

    /// The input with metadata stripped but pixels untouched, or the input itself if
    /// stripping would make it larger (WebP is returned unchanged by design).
    private func losslesslyStripped(_ input: Data, image: ImageData) throws -> Data {
        let stripped: Data
        switch image.format {
        case .jpeg: stripped = try JPEGCodec.losslessStrip(input, orientation: image.orientation)
        case .png: stripped = try PNGCodec.oxipng(input, strip: true)
        case .webp: return input
        }
        return stripped.count <= input.count ? stripped : input
    }

    private func checkCancelled() throws {
        if Task.isCancelled { throw OptimosError.cancelled }
    }
}
