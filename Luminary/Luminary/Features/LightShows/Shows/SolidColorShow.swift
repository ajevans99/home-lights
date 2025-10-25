import Foundation
import SwiftUI

@Observable
class SolidColorShow: LightShow {
  let id = "solid-color"
  let name = "Solid Color"
  let description = "Set all lights to the same color"
  let icon = "paintpalette.fill"

  var selectedColor: Color = .white

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    HSBColor(from: selectedColor)
  }

  func configurationView() -> AnyView {
    AnyView(SolidColorConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      let hsbColor = HSBColor(from: selectedColor)

      var writes: [(name: String, task: Task<Bool, Never>)] = []
      for (lightName, _) in lights {
        onColorUpdate(lightName, hsbColor)
        let task = controller.setLightColor(
          accessoryName: lightName,
          hue: hsbColor.hue,
          saturation: hsbColor.saturation,
          brightness: hsbColor.brightness
        )

        writes.append((lightName, task))
      }

      for (lightName, task) in writes {
        let success = await task.value

        if success {
          print("Successfully set color for \(lightName)")
        } else {
          print("Failed to set color for \(lightName)")
        }
      }
    }
  }
}
