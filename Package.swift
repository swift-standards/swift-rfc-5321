// swift-tools-version:6.2

import PackageDescription

let package = Package(
    name: "swift-rfc-5321",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26)
    ],
    products: [
        .library(name: "RFC 5321", targets: ["RFC 5321"])
    ],
    dependencies: [
        .package(path: "../../swift-foundations/swift-ascii"),
        .package(path: "../swift-rfc-1123")
    ],
    targets: [
        .target(
            name: "RFC 5321",
            dependencies: [
                .product(name: "RFC 1123", package: "swift-rfc-1123"),
                .product(name: "ASCII", package: "swift-ascii")
    ]
        )
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
