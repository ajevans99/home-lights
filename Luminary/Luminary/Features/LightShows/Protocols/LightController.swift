import Foundation

/// Protocol for controlling light colors.
///
/// Implementations return a `Task` that represents the debounced HomeKit write.
/// Callers can choose to `await` the task for completion or ignore it for fire-and-forget
/// semantics when best-effort updates are acceptable.
protocol LightController {
  @discardableResult
  func setLightColor(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double
  ) -> Task<Bool, Never>
}

extension LightController {
  /// Convenience helper for callers that need to suspend until the write finishes.
  func setLightColorAndWait(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double
  ) async -> Bool {
    let task = setLightColor(
      accessoryName: accessoryName,
      hue: hue,
      saturation: saturation,
      brightness: brightness
    )
    return await task.value
  }
}
