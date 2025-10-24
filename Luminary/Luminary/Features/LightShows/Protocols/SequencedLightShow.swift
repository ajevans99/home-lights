import Foundation

/// Protocol for light shows that use sequential ordering
protocol SequencedLightShow: LightShow {
  var orderingStrategy: LightOrderingStrategy { get set }

  /// Get the light sequence based on the ordering strategy
  func getSequence(for lights: [(name: String, position: CGPoint)]) -> [String]
}
