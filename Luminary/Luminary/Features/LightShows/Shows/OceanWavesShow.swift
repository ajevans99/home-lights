import Foundation
import SwiftUI

@Observable
class OceanWavesShow: LightShow {
  let id = "ocean-waves"
  let name = "Ocean Waves"
  let description = "Blue/teal colors undulate smoothly"
  let icon = "water.waves"

  var speed: Double = 2.0  // seconds per wave
  var waveIntensity: Double = 0.7

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(OceanWavesConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      let positions = lights.map { $0.position }
      let minY = positions.map { $0.y }.min() ?? 0
      let maxY = positions.map { $0.y }.max() ?? 1

      var wavePhase: Double = 0

      while !Task.isCancelled {
        for (lightName, position) in lights {
          guard !Task.isCancelled else { break }

          // Vertical position affects timing
          let normalizedY = (position.y - minY) / (maxY - minY)
          let phase = (wavePhase + normalizedY) * 2 * .pi

          // Oscillate between deep blue and bright teal
          let brightness = 40 + (sin(phase) * 40 * waveIntensity)
          let hue = 180 + (sin(phase) * 20)  // Cyan/teal range

          let color = HSBColor(hue: hue, saturation: 85, brightness: brightness)

          onColorUpdate(lightName, color)
          controller.setLightColor(
            accessoryName: lightName,
            hue: color.hue,
            saturation: color.saturation,
            brightness: color.brightness
          )
        }

        wavePhase += 0.05
        try? await Task.sleep(for: .seconds(speed / 20))
      }
    }
  }
}
