import Foundation
import SwiftUI

/// Protocol for light show sequences that can be applied to lights
protocol LightShow: Identifiable {
  var id: String { get }
  var name: String { get }
  var description: String { get }
  var icon: String { get }

  /// Calculate the color for a specific light at a given time
  /// - Parameters:
  ///   - light: The light accessory
  ///   - position: The position of the light on the canvas
  ///   - time: Current time in seconds (for animations)
  /// - Returns: The color to apply to this light
  func color(
    for light: String,
    at position: CGPoint,
    time: TimeInterval
  ) -> HSBColor?

  /// View for configuring the light show parameters
  @ViewBuilder
  func configurationView() -> AnyView
}

/// HSB Color representation for HomeKit compatibility
struct HSBColor: Equatable, Codable {
  let hue: Double  // 0-360
  let saturation: Double  // 0-100
  let brightness: Double  // 0-100

  init(hue: Double, saturation: Double, brightness: Double) {
    self.hue = hue
    self.saturation = saturation
    self.brightness = brightness
  }

  init(from color: Color) {
    // Extract HSB from SwiftUI Color using NSColor on macOS
    #if os(macOS)
      let nsColor = NSColor(color)
      var h: CGFloat = 0
      var s: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0

      nsColor.usingColorSpace(.deviceRGB)?.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

      self.hue = Double(h) * 360.0
      self.saturation = Double(s) * 100.0
      self.brightness = Double(b) * 100.0
    #else
      let uiColor = UIColor(color)
      var h: CGFloat = 0
      var s: CGFloat = 0
      var b: CGFloat = 0
      var a: CGFloat = 0

      uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)

      self.hue = Double(h) * 360.0
      self.saturation = Double(s) * 100.0
      self.brightness = Double(b) * 100.0
    #endif
  }

  var color: Color {
    Color(hue: hue / 360.0, saturation: saturation / 100.0, brightness: brightness / 100.0)
  }
}

// MARK: - Solid Color Show

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
}

struct SolidColorConfigView: View {
  @Bindable var show: SolidColorShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Select Color")
        .font(.headline)

      ColorPicker("Color", selection: $show.selectedColor)
        .labelsHidden()
        .frame(height: 200)

      Text("This will set all lights to the selected color")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
  }
}

// MARK: - Light Show Registry

@Observable
class LightShowRegistry {
  var availableShows: [any LightShow] = []
  var currentShow: (any LightShow)?

  init() {
    registerDefaultShows()
  }

  private func registerDefaultShows() {
    availableShows = [
      SolidColorShow()
    ]
  }

  func register(show: any LightShow) {
    availableShows.append(show)
  }
}
