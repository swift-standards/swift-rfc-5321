// swift-tools-version:6.0

import Foundation
import PackageDescription

extension String {
    static let rfc5321: Self = "RFC_5321"
}

extension Target.Dependency {
    static var rfc5321: Self { .target(name: .rfc5321) }
    static var rfc1123: Self { .product(name: "RFC_1123", package: "swift-rfc-1123") }
}

let package = Package(
    name: "swift-rfc-5321",
    platforms: [
        .macOS(.v13),
        .iOS(.v16)
    ],
    products: [
        .library(name: .rfc5321, targets: [.rfc5321]),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-standards/swift-rfc-1123.git", from: "0.0.1"),
    ],
    targets: [
        .target(
            name: .rfc5321,
            dependencies: [
                .rfc1123
            ]
        ),
        .testTarget(
            name: .rfc5321.tests,
            dependencies: [
                .rfc5321
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

extension String { var tests: Self { self + " Tests" } }