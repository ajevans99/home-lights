import Foundation
import SwiftUI

@Observable
class NeonPartyShow: LightShow {
  let id = "neon-party"
  let name = "Neon Party"
  let description = "Electric gradients, sparkles, and rotating neon washes"
  let icon = "sparkles"

  var palette: Palette = .neon
  var speed: Double = 0.35
  var sparkleChance: Double = 0.25
  var baseBrightness: Double = 70

  enum Palette: String, CaseIterable, Identifiable {
    case neon = "Neon Glow"
    case tropical = "Tropical Night"
    case cyber = "Cyber Pulse"

    var id: String { rawValue }

    var colors: [HSBColor] {
      switch self {
      case .neon:
        return [
          HSBColor(hue: 300, saturation: 90, brightness: 90),
          HSBColor(hue: 200, saturation: 100, brightness: 85),
          HSBColor(hue: 130, saturation: 90, brightness: 80),
          HSBColor(hue: 50, saturation: 100, brightness: 95),
        ]
      case .tropical:
        return [
          HSBColor(hue: 20, saturation: 90, brightness: 95),
          HSBColor(hue: 45, saturation: 100, brightness: 90),
          HSBColor(hue: 90, saturation: 80, brightness: 85),
          HSBColor(hue: 170, saturation: 80, brightness: 90),
        ]
      case .cyber:
        return [
          HSBColor(hue: 190, saturation: 100, brightness: 95),
          HSBColor(hue: 330, saturation: 90, brightness: 90),
          HSBColor(hue: 130, saturation: 80, brightness: 85),
          HSBColor(hue: 280, saturation: 100, brightness: 88),
        ]
      }
    }

    var icon: String {
      switch self {
      case .neon: return "bolt.horizontal.circle"
      case .tropical: return "sun.max"
      case .cyber: return "globe"
      }
    }

    var tagline: String {
      switch self {
      case .neon: return "Radiant magentas and laser blues"
      case .tropical: return "Warm sunset paired with lagoon greens"
      case .cyber: return "Holographic blues with neon violets"
      }
    }
  }

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(NeonPartyConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      var phase: Double = 0
      let tick: Double = 0.12

      while !Task.isCancelled {
        let colors = palette.colors
        guard !colors.isEmpty else { return }

        var writes: [Task<Bool, Never>] = []
        for (index, light) in lights.enumerated() {
          let paletteIndex = (Int(phase * Double(colors.count)) + index) % colors.count
          var color = colors[paletteIndex]

          let normalizedIndex = Double(index) / Double(max(1, lights.count - 1))
          let wave = (sin((phase + normalizedIndex) * .pi * 2) + 1) / 2
          let brightness = baseBrightness + ((100 - baseBrightness) * wave)
          color = HSBColor(
            hue: color.hue,
            saturation: color.saturation,
            brightness: min(100, max(20, brightness))
          )

          if Double.random(in: 0...1) < sparkleChance {
            let sparkleBoost = Double.random(in: 0.8...1.0)
            color = HSBColor(
              hue: color.hue,
              saturation: min(100, color.saturation + Double.random(in: 0...10)),
              brightness: min(100, color.brightness * sparkleBoost + 10)
            )
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

        phase += speed * tick
        if phase > 1 { phase -= 1 }

        try? await Task.sleep(for: .seconds(tick))
      }
    }
  }
}
