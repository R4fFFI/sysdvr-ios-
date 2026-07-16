// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SysDVRClient",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "SysDVRClient", targets: ["SysDVRClient"])
    ],
    dependencies: [
        // MobileVLCKit via CocoaPods is more reliable on iOS.
        // This Package.swift is for project structure reference only.
        // Use the Podfile below for actual dependency management.
    ],
    targets: [
        .target(name: "SysDVRClient", path: "SysDVRClient")
    ]
)
