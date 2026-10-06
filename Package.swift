// swift-tools-version: 6.0
import PackageDescription

let webpLib = "/opt/homebrew/opt/webp/lib"

let package = Package(
    name: "Optimos",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "OptimosCore", targets: ["OptimosCore"]),
        .executable(name: "optimos", targets: ["optimos"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        .systemLibrary(name: "CWebP", path: "Sources/CWebP"),
        .target(
            name: "OptimosCore",
            dependencies: ["CWebP"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "\(webpLib)/libwebp.a",
                    "-Xlinker", "\(webpLib)/libsharpyuv.a",
                ]),
            ]
        ),
        .executableTarget(
            name: "optimos",
            dependencies: [
                "OptimosCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(name: "OptimosCoreTests", dependencies: ["OptimosCore"]),
    ]
)
