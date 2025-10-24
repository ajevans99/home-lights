import Foundation
import SwiftUI

@Observable
class WaveColorShow: LightShow, SequencedLightShow {
  let id = "wave-color"
  let name = "Wave Color"
  let description = "Wave a color through lights one at a time"
  let icon = "waveform"

  var waveColor: Color = .green
  var restColor: Color = .white
  var durationPerLight: Double = 1.0
  var orderingStrategy: LightOrderingStrategy = .leftToRight

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    HSBColor(from: restColor)
  }

  func configurationView() -> AnyView {
    AnyView(WaveColorConfigView(show: self))
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

      let restHSB = HSBColor(from: restColor)
      let waveHSB = HSBColor(from: waveColor)

      // Set all lights to rest color initially
      for lightName in sequence {
        onColorUpdate(lightName, restHSB)
        controller.setLightColor(
          accessoryName: lightName,
          hue: restHSB.hue,
          saturation: restHSB.saturation,
          brightness: restHSB.brightness
        ) { _ in }
      }

      try? await Task.sleep(for: .seconds(0.5))

      // Wave through each light
      for lightName in sequence {
        guard !Task.isCancelled else { break }

        onColorUpdate(lightName, waveHSB)
        controller.setLightColor(
          accessoryName: lightName,
          hue: waveHSB.hue,
          saturation: waveHSB.saturation,
          brightness: waveHSB.brightness
        ) { success in
          if success {
            print("Wave hit \(lightName)")
          }
        }

        try? await Task.sleep(for: .seconds(durationPerLight))

        guard !Task.isCancelled else { break }
        onColorUpdate(lightName, restHSB)
        controller.setLightColor(
          accessoryName: lightName,
          hue: restHSB.hue,
          saturation: restHSB.saturation,
          brightness: restHSB.brightness
        ) { _ in }
      }
    }
  }
}
