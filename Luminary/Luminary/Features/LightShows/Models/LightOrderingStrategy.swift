import Foundation

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
      return lights.map { $0.name }
    }
  }

  private func calculateNearestNeighborSequence(lights: [(name: String, position: CGPoint)])
    -> [String]
  {
    guard !lights.isEmpty else { return [] }

    var remaining = lights
    var sequence: [String] = []

    let first = remaining.min(by: { $0.position.x < $1.position.x })!
    sequence.append(first.name)
    remaining.removeAll { $0.name == first.name }

    var currentPosition = first.position

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
