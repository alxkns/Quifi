// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "QuiFi",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "QuiFi", targets: ["QuiFi"]),
        .library(name: "QuiFiKit", targets: ["QuiFiKit"])
    ],
    targets: [
        .target(
            name: "QuiFiKit",
            path: "Sources/QuiFiKit"
        ),
        .executableTarget(
            name: "QuiFi",
            dependencies: ["QuiFiKit"],
            path: "Sources/QuiFi",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "QuiFiTests",
            dependencies: ["QuiFiKit"],
            path: "Tests/QuiFiTests"
        )
    ]
)
