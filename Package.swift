// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WeeChatKit",
    platforms: [
        .macOS(.v11),
        .iOS(.v15),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "WeeChatKit",
            targets: ["WeeChatKit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio", .upToNextMajor(from: "2.51.1")),
        .package(url: "https://github.com/apple/swift-nio-ssl", .upToNextMajor(from: "2.24.0")),
        .package(url: "https://github.com/apple/swift-nio-transport-services", .upToNextMajor(from: "1.17.0")),
        .package(url: "https://github.com/awxkee/zstd.swift", .upToNextMajor(from: "1.0.1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "WeeChatKit",
            dependencies: [
                .product(name: "NIO", package: "swift-nio"), 
                .product(name: "NIOWebSocket", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "NIOTransportServices", package: "swift-nio-transport-services"),
                .product(name: "zstd", package: "zstd.swift")
            ]),
        .testTarget(
            name: "WeeChatKitTests",
            dependencies: ["WeeChatKit"]),
    ]
)
