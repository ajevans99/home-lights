import Foundation
import SwiftUI

@Observable
class BassDropShow: LightShow {
  let id = "bass-drop"
  let name = "Bass Drop"
  let description = "Build-up pulses and explosive drops for dance floors"
  let icon = "speaker.wave.3"

  var primaryColor: Color = .blue
  var accentColor: Color = .pink
  var dropInterval: Double = 6.0
  var buildUpDuration: Double = 3.0
  var flashDuration: Double = 0.8
  var shimmerAmount: Double = 0.3

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(BassDropConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      var timeSinceDrop: Double = 0
      var dropActiveTime: Double = 0

      let tick: Double = 0.1

      while !Task.isCancelled {
        let flashBrightness: Double = 100
        let primaryHSB = HSBColor(from: primaryColor)
        let accentHSB = HSBColor(from: accentColor)

        timeSinceDrop += tick
        dropActiveTime -= tick

        if timeSinceDrop >= dropInterval {
          timeSinceDrop = 0
          dropActiveTime = flashDuration
        }

        let buildProgress = min(1, timeSinceDrop / buildUpDuration)
        let baseWave = (sin(buildProgress * .pi * 2) + 1) / 2

        var writes: [Task<Bool, Never>] = []
        for (index, light) in lights.enumerated() {
          let offset = Double(index) / Double(max(1, lights.count - 1))
          let shimmer = (sin((timeSinceDrop + offset) * 12) + 1) / 2

          var color: HSBColor
          if dropActiveTime > 0 {
            let dropFade = max(0, dropActiveTime / flashDuration)
            let brightness = flashBrightness * dropFade
            color = HSBColor(
              hue: accentHSB.hue,
              saturation: min(100, accentHSB.saturation + 10),
              brightness: min(100, brightness)
            )
          } else {
            let brightnessBoost = baseWave * 40 + shimmer * shimmerAmount * 30
            color = HSBColor(
              hue: primaryHSB.hue,
              saturation: primaryHSB.saturation,
              brightness: min(100, max(15, primaryHSB.brightness + brightnessBoost))
            )

            if index.isMultiple(of: 3) {
              color = HSBColor(
                hue: accentHSB.hue,
                saturation: accentHSB.saturation,
                brightness: min(100, color.brightness + 10)
              )
            }
          }

          onColorUpdate(light.name, color)
          writes.append(
            controller.setLightColor(
              accessoryName: light.name,
              hue: color.hue,
              saturation: color.saturation,
              brightness: color.brightness
            )
          )
        }

        for task in writes {
          _ = await task.value
        }

        try? await Task.sleep(for: .seconds(tick))
      }
    }
  }
}
