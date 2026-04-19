// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GGGTranslate",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "GGGTranslate",
            path: "Sources",
            resources: [
                .copy("Resources")
            ],
            linkerSettings: [
                .linkedFramework("Cocoa"),
                .linkedFramework("WebKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ]
)
