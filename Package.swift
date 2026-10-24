// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "RELAY",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "RelayCore", targets: ["RelayCore"]),
               .executable(name: "RelayLab", targets: ["RelayLab"]),
               .executable(name: "RelayCloudCheck", targets: ["RelayCloudCheck"]),
               .executable(name: "RelayWorkflowCheck", targets: ["RelayWorkflowCheck"])],
    targets: [
        .target(name: "RelayCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "RelayLab", dependencies: ["RelayCore"]),
        .executableTarget(name: "RelayCloudCheck", dependencies: ["RelayCore"]),
        .executableTarget(name: "RelayWorkflowCheck", dependencies: ["RelayCore"]),
        .testTarget(name: "RelayCoreTests", dependencies: ["RelayCore"])
    ],
    swiftLanguageModes: [.v5]
)
