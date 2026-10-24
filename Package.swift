// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "RELAY",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "RelayCore", targets: ["RelayCore"]),
               .executable(name: "RelayLab", targets: ["RelayLab"]),
               .executable(name: "RelayCloudCheck", targets: ["RelayCloudCheck"])],
    targets: [
        .target(name: "RelayCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "RelayLab", dependencies: ["RelayCore"]),
        .executableTarget(name: "RelayCloudCheck", dependencies: ["RelayCore"]),
        .testTarget(name: "RelayCoreTests", dependencies: ["RelayCore"])
    ],
    swiftLanguageModes: [.v5]
)
