import Foundation

/// Protocol for controlling light colors
protocol LightController {
  func setLightColor(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double
  ) async -> Bool
}
