import Foundation
import SwiftUI

@Observable
class StrobeShow: LightShow {
  let id = "strobe"
  let name = "Strobe"
  let description = "Configurable strobe effect with color and speed"
  let icon = "bolt.fill"

  var strobeColor: Color = .white
  var speed: Double = 0.2  // seconds between flashes
  var intensity: Double = 100  // brightness

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    HSBColor(from: strobeColor)
  }

  func configurationView() -> AnyView {
    AnyView(StrobeConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      let color = HSBColor(from: strobeColor)
      let onColor = HSBColor(
        hue: color.hue,
        saturation: color.saturation,
        brightness: intensity
      )
      let offColor = HSBColor(hue: color.hue, saturation: color.saturation, brightness: 0)

      while !Task.isCancelled {
        // Flash on
        var flashOnWrites: [Task<Bool, Never>] = []
        for (lightName, _) in lights {
          onColorUpdate(lightName, onColor)
          let task = controller.setLightColor(
            accessoryName: lightName,
            hue: onColor.hue,
            saturation: onColor.saturation,
            brightness: onColor.brightness
          )
          flashOnWrites.append(task)
        }

        for task in flashOnWrites {
          _ = await task.value
        }

        try? await Task.sleep(for: .seconds(speed / 4))
        guard !Task.isCancelled else { break }

        // Flash off
        var flashOffWrites: [Task<Bool, Never>] = []
        for (lightName, _) in lights {
          onColorUpdate(lightName, offColor)
          let task = controller.setLightColor(
            accessoryName: lightName,
            hue: offColor.hue,
            saturation: offColor.saturation,
            brightness: offColor.brightness
          )
          flashOffWrites.append(task)
        }

        for task in flashOffWrites {
          _ = await task.value
        }

        try? await Task.sleep(for: .seconds(speed))
      }
    }
  }
}
