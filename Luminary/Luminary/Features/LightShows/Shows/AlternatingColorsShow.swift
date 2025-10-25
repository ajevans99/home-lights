import Foundation
import SwiftUI

@Observable
class AlternatingColorsShow: LightShow {
  let id = "alternating-colors"
  let name = "Alternating Colors"
  let description = "Lights alternate between two colors and swap periodically"
  let icon = "checkerboard.rectangle"

  var primaryColor: Color = .green
  var secondaryColor: Color = .white
  var switchInterval: Double = 2.0

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(AlternatingColorsConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      var isSwapped = false

      while !Task.isCancelled {
        let currentPrimary = HSBColor(from: primaryColor)
        let currentSecondary = HSBColor(from: secondaryColor)

        let evenColor = isSwapped ? currentSecondary : currentPrimary
        let oddColor = isSwapped ? currentPrimary : currentSecondary

        var tasks: [Task<Bool, Never>] = []
        for (index, light) in lights.enumerated() {
          let color = index.isMultiple(of: 2) ? evenColor : oddColor
          onColorUpdate(light.name, color)
          tasks.append(
            controller.setLightColor(
              accessoryName: light.name,
              hue: color.hue,
              saturation: color.saturation,
              brightness: color.brightness
            )
          )
        }

        for task in tasks {
          _ = await task.value
        }

        guard !Task.isCancelled else { break }
        isSwapped.toggle()

        let interval = max(0.1, switchInterval)
        try? await Task.sleep(for: .seconds(interval))
      }
    }
  }
}
