import Foundation
import SwiftUI

@Observable
class TwinkleShow: LightShow {
  let id = "twinkle"
  let name = "Twinkle"
  let description = "Random lights sparkle like stars"
  let icon = "sparkles"

  var baseColor: Color = .white
  var twinkleColor: Color = .yellow
  var frequency: Double = 0.3  // probability per light per interval

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    HSBColor(from: baseColor)
  }

  func configurationView() -> AnyView {
    AnyView(TwinkleConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      let baseHSB = HSBColor(from: baseColor)
      let twinkleHSB = HSBColor(from: twinkleColor)

      // Set all to base color initially
      for (lightName, _) in lights {
        onColorUpdate(lightName, baseHSB)
        _ = await controller.setLightColor(
          accessoryName: lightName,
          hue: baseHSB.hue,
          saturation: baseHSB.saturation,
          brightness: baseHSB.brightness
        )
      }

      try? await Task.sleep(for: .seconds(0.5))

      while !Task.isCancelled {
        // Random twinkle
        for (lightName, _) in lights {
          guard !Task.isCancelled else { break }

          if Double.random(in: 0...1) < frequency {
            // Twinkle this light
            onColorUpdate(lightName, twinkleHSB)
            _ = await controller.setLightColor(
              accessoryName: lightName,
              hue: twinkleHSB.hue,
              saturation: twinkleHSB.saturation,
              brightness: twinkleHSB.brightness
            )

            // Return to base after a moment
            Task {
              try? await Task.sleep(for: .seconds(0.2))
              onColorUpdate(lightName, baseHSB)
              _ = await controller.setLightColor(
                accessoryName: lightName,
                hue: baseHSB.hue,
                saturation: baseHSB.saturation,
                brightness: baseHSB.brightness
              )
            }
          }
        }

        try? await Task.sleep(for: .seconds(0.5))
      }
    }
  }
}
