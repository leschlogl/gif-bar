// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "GIFBarKit",
    platforms: [.macOS(.v26)],
    products: [
        .library(name: "Utilities", targets: ["Utilities"]),
        .library(name: "Models", targets: ["Models"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "Persistence", targets: ["Persistence"]),
        .library(name: "Services", targets: ["Services"]),
        .library(name: "ViewModels", targets: ["ViewModels"]),
        .library(name: "Views", targets: ["Views"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.0"),
    ],
    targets: [
        .target(name: "Utilities"),
        .target(name: "Models", dependencies: ["Utilities"]),
        .target(name: "DesignSystem", dependencies: ["Utilities"]),
        .target(name: "Networking", dependencies: ["Models", "Utilities"]),
        .target(name: "Persistence", dependencies: ["Models", "Utilities"]),
        .target(name: "Services", dependencies: ["Networking", "Persistence", "Models"]),
        .target(name: "ViewModels", dependencies: ["Services", "Models", "Utilities"]),
        .target(name: "Views", dependencies: ["ViewModels", "DesignSystem", "Models"]),

        .testTarget(name: "UtilitiesTests", dependencies: ["Utilities"]),
        .testTarget(name: "ModelsTests", dependencies: ["Models"]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking"]),
        .testTarget(name: "PersistenceTests", dependencies: ["Persistence"]),
        .testTarget(name: "ServicesTests", dependencies: ["Services"]),
        .testTarget(name: "ViewModelsTests", dependencies: ["ViewModels"]),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: [
                "DesignSystem",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
        .testTarget(
            name: "ViewsTests",
            dependencies: [
                "Views",
                .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
            ]
        ),
    ]
)
