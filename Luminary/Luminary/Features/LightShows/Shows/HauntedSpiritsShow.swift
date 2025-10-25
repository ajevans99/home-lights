import Foundation
import SwiftUI

@Observable
class HauntedSpiritsShow: LightShow {
  let id = "haunted-spirits"
  let name = "Haunted Spirits"
  let description = "Eerie pulses, ghostly flickers, and spectral strobes"
  let icon = "moon.stars"

  var baseColor: Color = .purple
  var accentColor: Color = .orange
  var flickerIntensity: Double = 0.6
  var pulseInterval: Double = 3.0
  var strobeChance: Double = 0.2

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    nil
  }

  func configurationView() -> AnyView {
    AnyView(HauntedSpiritsConfigView(show: self))
  }

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      guard !lights.isEmpty else { return }

      var elapsed: Double = 0
      var lastPulse = Date()
      let tickInterval: Double = 0.15

      while !Task.isCancelled {
        let now = Date()
        let shouldPulse = now.timeIntervalSince(lastPulse) >= max(0.5, pulseInterval)
        if shouldPulse {
          lastPulse = now
        }

        let baseHSB = HSBColor(from: baseColor)
        let accentHSB = HSBColor(from: accentColor)

        var writes: [Task<Bool, Never>] = []
        for (index, light) in lights.enumerated() {
          let progress = Double(index) / Double(max(1, lights.count - 1))
          let wave = (sin((elapsed + progress) * .pi * 2) + 1) / 2
          var color = blend(base: baseHSB, accent: accentHSB, factor: wave)

          if Double.random(in: 0...1) < flickerIntensity {
            let flicker = Double.random(in: 0.55...1.0)
            color = HSBColor(
              hue: color.hue,
              saturation: color.saturation,
              brightness: min(100, color.brightness * flicker)
            )
          }

          if shouldPulse && index.isMultiple(of: 2) {
            color = HSBColor(
              hue: accentHSB.hue,
              saturation: 100,
              brightness: 100
            )
          } else if Double.random(in: 0...1) < strobeChance && index.isMultiple(of: 5) {
            color = HSBColor(hue: 40, saturation: 30, brightness: 100)
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

        try? await Task.sleep(for: .seconds(tickInterval))
        elapsed += tickInterval
      }
    }
  }

  private func blend(base: HSBColor, accent: HSBColor, factor: Double) -> HSBColor {
    let t = max(0, min(1, factor))
    let hue = base.hue + (accent.hue - base.hue) * t
    let saturation = base.saturation + (accent.saturation - base.saturation) * t
    let brightness = base.brightness + (accent.brightness - base.brightness) * t
    return HSBColor(
      hue: hue,
      saturation: max(0, min(100, saturation)),
      brightness: max(0, min(100, brightness))
    )
  }
}
