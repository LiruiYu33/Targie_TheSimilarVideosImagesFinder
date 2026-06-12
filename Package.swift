// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SimilarVideoFinder",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "SimilarVideoFinder", targets: ["SimilarVideoFinder"])
    ],
    targets: [
        .executableTarget(name: "SimilarVideoFinder", path: "Sources/SimilarVideoFinder"),
        .testTarget(
            name: "SimilarVideoFinderTests",
            dependencies: ["SimilarVideoFinder"],
            path: "Tests/SimilarVideoFinderTests"
        )
    ]
)
