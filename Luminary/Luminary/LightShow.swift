import Foundation
import HomeLights
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

  /// Apply the light show to a set of lights
  /// - Parameters:
  ///   - lights: Array of light names and their positions
  ///   - controller: The controller for setting light colors
  ///   - onColorUpdate: Callback when a light's preview color should update
  /// - Returns: A task that can be cancelled to stop the show
  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never>
}

/// Protocol for controlling light colors
protocol LightController {
  func setLightColor(
    accessoryName: String,
    hue: Double,
    saturation: Double,
    brightness: Double,
    completion: @escaping (Bool) -> Void
  )
}

// Make HomeLights conform to LightController
extension HomeLights: LightController {}

/// Protocol for light shows that use sequential ordering
protocol SequencedLightShow: LightShow {
  var orderingStrategy: LightOrderingStrategy { get set }

  /// Get the light sequence based on the ordering strategy
  func getSequence(for lights: [(name: String, position: CGPoint)]) -> [String]
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

// MARK: - Light Ordering Strategy

enum LightOrderingStrategy: String, CaseIterable, Identifiable {
  case leftToRight = "Left to Right"
  case rightToLeft = "Right to Left"
  case topToBottom = "Top to Bottom"
  case bottomToTop = "Bottom to Top"
  case nearestNeighbor = "Nearest Neighbor"
  case custom = "Custom Order"

  var id: String { rawValue }

  var icon: String {
    switch self {
    case .leftToRight: return "arrow.right"
    case .rightToLeft: return "arrow.left"
    case .topToBottom: return "arrow.down"
    case .bottomToTop: return "arrow.up"
    case .nearestNeighbor: return "point.3.connected.trianglepath.dotted"
    case .custom: return "list.number"
    }
  }

  var description: String {
    switch self {
    case .leftToRight: return "Lights ordered from left to right by X position"
    case .rightToLeft: return "Lights ordered from right to left by X position"
    case .topToBottom: return "Lights ordered from top to bottom by Y position"
    case .bottomToTop: return "Lights ordered from bottom to top by Y position"
    case .nearestNeighbor: return "Each light travels to its nearest neighbor"
    case .custom: return "Use a custom saved order"
    }
  }

  /// Calculate the ordered sequence based on this strategy
  func calculateSequence(lights: [(name: String, position: CGPoint)]) -> [String] {
    switch self {
    case .leftToRight:
      return lights.sorted { $0.position.x < $1.position.x }.map { $0.name }
    case .rightToLeft:
      return lights.sorted { $0.position.x > $1.position.x }.map { $0.name }
    case .topToBottom:
      return lights.sorted { $0.position.y < $1.position.y }.map { $0.name }
    case .bottomToTop:
      return lights.sorted { $0.position.y > $1.position.y }.map { $0.name }
    case .nearestNeighbor:
      return calculateNearestNeighborSequence(lights: lights)
    case .custom:
      // For now, return as-is. Could be extended with saved custom orders
      return lights.map { $0.name }
    }
  }

  private func calculateNearestNeighborSequence(lights: [(name: String, position: CGPoint)])
    -> [String]
  {
    guard !lights.isEmpty else { return [] }

    var remaining = lights
    var sequence: [String] = []

    // Start with leftmost light
    let first = remaining.min(by: { $0.position.x < $1.position.x })!
    sequence.append(first.name)
    remaining.removeAll { $0.name == first.name }

    var currentPosition = first.position

    // Keep finding nearest neighbor
    while !remaining.isEmpty {
      let nearest = remaining.min(by: { light1, light2 in
        distance(from: currentPosition, to: light1.position)
          < distance(from: currentPosition, to: light2.position)
      })!

      sequence.append(nearest.name)
      currentPosition = nearest.position
      remaining.removeAll { $0.name == nearest.name }
    }

    return sequence
  }

  private func distance(from p1: CGPoint, to p2: CGPoint) -> CGFloat {
    let dx = p1.x - p2.x
    let dy = p1.y - p2.y
    return sqrt(dx * dx + dy * dy)
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

  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never> {
    Task {
      let hsbColor = HSBColor(from: selectedColor)

      for (lightName, _) in lights {
        // Update preview
        onColorUpdate(lightName, hsbColor)

        // Apply to HomeKit
        controller.setLightColor(
          accessoryName: lightName,
          hue: hsbColor.hue,
          saturation: hsbColor.saturation,
          brightness: hsbColor.brightness
        ) { success in
          if success {
            print("Successfully set color for \(lightName)")
          } else {
            print("Failed to set color for \(lightName)")
          }
        }
      }
    }
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

// MARK: - Wave Color Show

@Observable
class WaveColorShow: LightShow, SequencedLightShow {
  let id = "wave-color"
  let name = "Wave Color"
  let description = "Wave a color through lights one at a time"
  let icon = "waveform"

  var waveColor: Color = .green
  var restColor: Color = .white
  var durationPerLight: Double = 1.0  // seconds each light stays lit
  var orderingStrategy: LightOrderingStrategy = .leftToRight

  func color(for light: String, at position: CGPoint, time: TimeInterval) -> HSBColor? {
    // This will be calculated based on the sequence and current time
    // For now, return rest color - actual sequencing happens in applyShow
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

      // Wait for initial state
      try? await Task.sleep(for: .seconds(0.5))

      // Wave through each light
      for lightName in sequence {
        guard !Task.isCancelled else { break }

        // Turn to wave color
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

        // Wait for duration
        try? await Task.sleep(for: .seconds(durationPerLight))

        // Return to rest color
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

struct WaveColorConfigView: View {
  @Bindable var show: WaveColorShow

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("Wave Color")
        .font(.headline)

      ColorPicker("Wave Color", selection: $show.waveColor)

      ColorPicker("Rest Color", selection: $show.restColor)

      VStack(alignment: .leading, spacing: 8) {
        Text("Duration per Light: \(String(format: "%.1f", show.durationPerLight))s")
          .font(.subheadline)

        Slider(value: $show.durationPerLight, in: 0.1...5.0, step: 0.1)
      }

      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text("Order")
            .font(.subheadline)
          
          Spacer()
          
          Image(systemName: show.orderingStrategy.icon)
            .foregroundColor(.secondary)
        }

        Picker("Order", selection: $show.orderingStrategy) {
          ForEach(LightOrderingStrategy.allCases) { strategy in
            Label(strategy.rawValue, systemImage: strategy.icon).tag(strategy)
          }
        }
        .pickerStyle(.menu)
        
        Text(show.orderingStrategy.description)
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Text("Lights will wave in the selected order, one at a time")
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
      SolidColorShow(),
      WaveColorShow(),
    ]
  }

  func register(show: any LightShow) {
    availableShows.append(show)
  }
}
