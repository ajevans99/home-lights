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
    )
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
    .testTarget(
      name: "HomeLightsTests",
      dependencies: ["HomeLights"]
    ),
  ]
)
