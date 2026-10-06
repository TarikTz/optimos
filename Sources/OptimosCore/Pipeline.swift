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
            return ProcessedImage(bytes: input, format: inFormat, originalSize: input.count, newSize: input.count)
        }
        return ProcessedImage(bytes: bytes, format: outFormat, originalSize: input.count, newSize: bytes.count)
    }

    private func checkCancelled() throws {
        if Task.isCancelled { throw OptimosError.cancelled }
    }
}
