// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "RateBoardKit",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "RateBoardKit", targets: ["RateBoardKit"]),
    ],
    targets: [
        .target(name: "RateBoardKit"),
        .testTarget(name: "RateBoardKitTests", dependencies: ["RateBoardKit"]),
    ]
)
