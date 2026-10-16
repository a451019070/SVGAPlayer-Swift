// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SVGAPlayer-Swift",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "SVGAPlayer-Swift", targets: ["SVGAPlayer-Swift"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.39.0")
    ],
    targets: [
        .target(
            name: "SVGAPlayer-Swift",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            path: "Source"
        )
    ]
)
