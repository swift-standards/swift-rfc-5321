// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "swift-rfc-5321",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11)
    ],
    products: [
        .library(name: "RFC_5321", targets: ["RFC_5321"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986.git", from: "0.0.1"),
        .package(url: "https://github.com/swift-standards/swift-rfc-1123.git", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "RFC_5321",
            dependencies: [
                .product(name: "RFC_1123", package: "swift-rfc-1123"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986")
            ]
        ),
        .testTarget(
            name: "RFC_5321".tests,
            dependencies: [
                "RFC_5321"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }
