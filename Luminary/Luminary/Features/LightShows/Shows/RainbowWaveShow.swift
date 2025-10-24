import Foundation
import SwiftUI

@Observable
class RainbowWaveShow: LightShow, SequencedLightShow {
  let id = "rainbow-wave"
  let name = "Rainbow Wave"
  let description = "Cycle through rainbow colors in sequence"
  let icon = "rainbow"

  var speed: Double = 1.0  // seconds per light
  var orderingStrategy: LightOrderingStrategy = .leftToRight

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(RainbowWaveConfigView(show: self))
  }

  func getSequence(for lights: [(name: String, position: CGPoint)]) -> [String] {
    orderingStrategy.calculateSequence(lights: lights)
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      let sequence = getSequence(for: lights)
      guard !sequence.isEmpty else { return }

      let rainbowColors: [HSBColor] = [
        HSBColor(hue: 0, saturation: 100, brightness: 100),  // Red
        HSBColor(hue: 30, saturation: 100, brightness: 100),  // Orange
        HSBColor(hue: 60, saturation: 100, brightness: 100),  // Yellow
        HSBColor(hue: 120, saturation: 100, brightness: 100),  // Green
        HSBColor(hue: 180, saturation: 100, brightness: 100),  // Cyan
        HSBColor(hue: 240, saturation: 100, brightness: 100),  // Blue
        HSBColor(hue: 300, saturation: 100, brightness: 100),  // Magenta
      ]

      while !Task.isCancelled {
        for (index, lightName) in sequence.enumerated() {
          guard !Task.isCancelled else { break }

          let colorIndex = index % rainbowColors.count
          let color = rainbowColors[colorIndex]

          onColorUpdate(lightName, color)
          let success = await controller.setLightColor(
            accessoryName: lightName,
            hue: color.hue,
            saturation: color.saturation,
            brightness: color.brightness
          )
          if success {
            print("Rainbow wave hit \(lightName) with color \(colorIndex)")
          }

          try? await Task.sleep(for: .seconds(speed))
        }

        // Shift colors for next iteration
        try? await Task.sleep(for: .seconds(speed))
      }
    }
  }
}
