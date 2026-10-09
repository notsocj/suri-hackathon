// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SuriCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "SuriCore", targets: ["SuriCore"])],
    targets: [
        .target(name: "SuriCore"),
        .testTarget(name: "SuriCoreTests", dependencies: ["SuriCore"])
    ]
)
