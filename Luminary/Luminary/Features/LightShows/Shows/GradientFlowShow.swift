import Foundation
import SwiftUI

@Observable
class GradientFlowShow: LightShow {
  let id = "gradient-flow"
  let name = "Gradient Flow"
  let description = "Smooth color gradient flows across spatial layout"
  let icon = "chart.line.uptrend.xyaxis"

  var startColor: Color = .blue
  var endColor: Color = .red
  var speed: Double = 2.0  // seconds for full cycle
  var direction: GradientDirection = .horizontal

  enum GradientDirection: String, CaseIterable, Identifiable {
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case radial = "Radial"

    var id: String { rawValue }

    var icon: String {
      switch self {
      case .horizontal: return "arrow.left.and.right"
      case .vertical: return "arrow.up.and.down"
      case .radial: return "circle.circle"
      }
    }
  }

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(GradientFlowConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      let startHSB = HSBColor(from: startColor)
      let endHSB = HSBColor(from: endColor)

      // Find bounds
      let positions = lights.map { $0.position }
      let minX = positions.map { $0.x }.min() ?? 0
      let maxX = positions.map { $0.x }.max() ?? 1
      let minY = positions.map { $0.y }.min() ?? 0
      let maxY = positions.map { $0.y }.max() ?? 1
      let centerX = (minX + maxX) / 2
      let centerY = (minY + maxY) / 2
      let maxRadius = sqrt(pow(maxX - minX, 2) + pow(maxY - minY, 2)) / 2

      while !Task.isCancelled {
        for phase in stride(from: 0.0, to: 1.0, by: 0.05) {
          guard !Task.isCancelled else { break }

          for (lightName, position) in lights {
            let t: Double
            switch direction {
            case .horizontal:
              t = ((position.x - minX) / (maxX - minX) + phase).truncatingRemainder(
                dividingBy: 1.0
              )
            case .vertical:
              t = ((position.y - minY) / (maxY - minY) + phase).truncatingRemainder(
                dividingBy: 1.0
              )
            case .radial:
              let dist = sqrt(pow(position.x - centerX, 2) + pow(position.y - centerY, 2))
              t = ((dist / maxRadius) + phase).truncatingRemainder(dividingBy: 1.0)
            }

            let color = interpolateColor(from: startHSB, to: endHSB, t: t)

            onColorUpdate(lightName, color)
            controller.setLightColor(
              accessoryName: lightName,
              hue: color.hue,
              saturation: color.saturation,
              brightness: color.brightness
            )
          }

          try? await Task.sleep(for: .seconds(speed / 20))
        }
      }
    }
  }

  private func interpolateColor(from start: HSBColor, to end: HSBColor, t: Double) -> HSBColor {
    let hue = start.hue + (end.hue - start.hue) * t
    let sat = start.saturation + (end.saturation - start.saturation) * t
    let bri = start.brightness + (end.brightness - start.brightness) * t
    return HSBColor(hue: hue, saturation: sat, brightness: bri)
  }
}
