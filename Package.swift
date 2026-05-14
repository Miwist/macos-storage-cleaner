// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacosStorageCleaner",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(
            name: "MacosStorageCleaner",
            targets: ["CleanerApp"]
        ),
        .library(name: "CleanerCore", targets: ["CleanerCore"]),
        .library(name: "CleanerUI", targets: ["CleanerUI"]),
    ],
    targets: [
        .target(
            name: "CleanerCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .target(
            name: "CleanerUI",
            dependencies: ["CleanerCore"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
        .executableTarget(
            name: "CleanerApp",
            dependencies: ["CleanerCore", "CleanerUI"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
            ]
        ),
    ]
)
