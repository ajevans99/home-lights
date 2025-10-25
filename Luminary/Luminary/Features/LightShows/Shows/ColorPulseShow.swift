import Foundation
import SwiftUI

@Observable
class ColorPulseShow: LightShow {
  let id = "color-pulse"
  let name = "Color Pulse"
  let description = "All lights pulse in sync with adjustable rhythm"
  let icon = "waveform.path.ecg"

  var pulseColor: Color = .purple
  var speed: Double = 1.0  // seconds per pulse

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    HSBColor(from: pulseColor)
  }

  func configurationView() -> AnyView {
    AnyView(ColorPulseConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      let color = HSBColor(from: pulseColor)
      let dimColor = HSBColor(hue: color.hue, saturation: color.saturation, brightness: 10)

      while !Task.isCancelled {
        // Pulse up
        var pulseUpWrites: [Task<Bool, Never>] = []
        for (lightName, _) in lights {
          onColorUpdate(lightName, color)
          let task = controller.setLightColor(
            accessoryName: lightName,
            hue: color.hue,
            saturation: color.saturation,
            brightness: color.brightness
          )
          pulseUpWrites.append(task)
        }

        for task in pulseUpWrites {
          _ = await task.value
        }

        try? await Task.sleep(for: .seconds(speed / 2))
        guard !Task.isCancelled else { break }

        // Pulse down
        var pulseDownWrites: [Task<Bool, Never>] = []
        for (lightName, _) in lights {
          onColorUpdate(lightName, dimColor)
          let task = controller.setLightColor(
            accessoryName: lightName,
            hue: dimColor.hue,
            saturation: dimColor.saturation,
            brightness: dimColor.brightness
          )
          pulseDownWrites.append(task)
        }

        for task in pulseDownWrites {
          _ = await task.value
        }

        try? await Task.sleep(for: .seconds(speed / 2))
      }
    }
  }
}
