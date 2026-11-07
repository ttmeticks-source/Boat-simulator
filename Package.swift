// swift-tools-version:5.3
import PackageDescription
let package = Package(
    name: "BoatSimulator",
    platforms: [.macOS("11.0")],
    products: [.executable(name: "BoatSimulator", targets: ["BoatSimulator"])],
    targets: [.executableTarget(name: "BoatSimulator", path: "Sources/BoatSimulator")]
)
