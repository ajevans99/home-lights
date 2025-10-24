import Foundation
import SwiftUI

/// Protocol for light show sequences that can be applied to lights
protocol LightShow: Identifiable {
  var id: String { get }
  var name: String { get }
  var description: String { get }
  var icon: String { get }

  /// Calculate the color for a specific light at a given time
  func color(
    for light: String,
    at position: CGPoint,
    time: TimeInterval
  ) -> HSBColor?

  /// View for configuring the light show parameters
  @ViewBuilder
  func configurationView() -> AnyView

  /// Apply the light show to a set of lights
  func apply(
    to lights: [(name: String, position: CGPoint)],
    using controller: LightController,
    onColorUpdate: @escaping (String, HSBColor?) -> Void
  ) -> Task<Void, Never>
}
