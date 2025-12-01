// swift-tools-version:6.2

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
        .library(name: "RFC 5321", targets: ["RFC 5321"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-incits-4-1986.git", from: "0.6.0"),
        .package(url: "https://github.com/swift-standards/swift-rfc-1123.git", from: "0.4.0")
    ],
    targets: [
        .target(
            name: "RFC 5321",
            dependencies: [
                .product(name: "RFC 1123", package: "swift-rfc-1123"),
                .product(name: "INCITS 4 1986", package: "swift-incits-4-1986")
            ]
        ),
        .testTarget(
            name: "RFC 5321".tests,
            dependencies: [
                "RFC 5321"
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String {
    var tests: Self { self + " Tests" }
    var foundation: Self { self + " Foundation" }
}

for target in package.targets where ![.system, .binary, .plugin].contains(target.type) {
    let existing = target.swiftSettings ?? []
    target.swiftSettings = existing + [
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility")
    ]
}
