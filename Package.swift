// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "home-lights",
  defaultLocalization: "en",
  platforms: [
    .macCatalyst(.v18)
  ],
  products: [
    .library(
      name: "HomeLights",
      targets: ["HomeLights"]
    ),
    .executable(
      name: "Playground",
      targets: ["Playground"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
  ],
  targets: [
    .target(
      name: "HomeLights",
      linkerSettings: [
        .linkedFramework("HomeKit")
      ]
    ),
    .executableTarget(
      name: "Playground",
      dependencies: [
        "HomeLights",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .testTarget(
      name: "HomeLightsTests",
      dependencies: ["HomeLights"]
    ),
  ]
)
