// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "RELAY",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "RelayCore", targets: ["RelayCore"]),
               .executable(name: "RelayLab", targets: ["RelayLab"])],
    targets: [
        .target(name: "RelayCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "RelayLab", dependencies: ["RelayCore"]),
        .testTarget(name: "RelayCoreTests", dependencies: ["RelayCore"])
    ],
    swiftLanguageModes: [.v5]
)
