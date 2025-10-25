import Foundation
import SwiftUI

@Observable
class FireEffectShow: LightShow {
  let id = "fire-effect"
  let name = "Fire Effect"
  let description = "Flickering orange/red/yellow to simulate flames"
  let icon = "flame.fill"

  var intensity: Double = 0.8  // How wild the flicker is

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(FireEffectConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      while !Task.isCancelled {
        for (lightName, _) in lights {
          guard !Task.isCancelled else { break }

          // Random fire colors
          let hue = Double.random(in: 0...30)  // Red to orange range
          let saturation = Double.random(in: 80...100)
          let brightness = Double.random(in: (50 * intensity)...(100 * intensity))

          let color = HSBColor(hue: hue, saturation: saturation, brightness: brightness)

          onColorUpdate(lightName, color)
          controller.setLightColor(
            accessoryName: lightName,
            hue: color.hue,
            saturation: color.saturation,
            brightness: color.brightness
          )
        }

        // Random flicker timing
        let flickerDelay = Double.random(in: 0.05...0.2)
        try? await Task.sleep(for: .seconds(flickerDelay))
      }
    }
  }
}
