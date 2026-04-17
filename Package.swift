// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "videOS",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .systemLibrary(
            name: "CLibVLC",
            path: "Sources/CLibVLC",
            pkgConfig: nil,
            providers: [
                .brew(["vlc"])
            ]
        ),
        .executableTarget(
            name: "videOS",
            dependencies: ["CLibVLC"],
            path: "Sources/videOS",
            linkerSettings: [
                .unsafeFlags(["-L/Applications/VLC.app/Contents/MacOS/lib"]),
                .unsafeFlags(["-L/opt/homebrew/lib"], .when(platforms: [.macOS])),
                .unsafeFlags(["-L/usr/local/lib"], .when(platforms: [.macOS])),
                .linkedLibrary("vlc"),
                .linkedFramework("Cocoa"),
                .linkedFramework("QuartzCore"),
            ]
        ),
        .testTarget(
            name: "videOSTests",
            dependencies: ["videOS"],
            path: "Tests/videOSTests"
        ),
    ]
)
