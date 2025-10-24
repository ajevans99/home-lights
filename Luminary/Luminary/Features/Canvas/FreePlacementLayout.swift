import SwiftUI

struct FreePlacementLayout: Layout {
  @Binding var positions: [String: CGPoint]

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    proposal.replacingUnspecifiedDimensions()
  }

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    for subview in subviews {
      let size = subview.sizeThatFits(.unspecified)

      let position: CGPoint
      if let name = subview[LightNameKey.self],
        let storedPosition = positions[name]
      {
        position = storedPosition
      } else {
        position = CGPoint(x: bounds.midX, y: bounds.midY)
      }

      let placementPoint = CGPoint(
        x: position.x - size.width / 2,
        y: position.y - size.height / 2
      )

      subview.place(at: placementPoint, proposal: .unspecified)
    }
  }
}

struct LightNameKey: LayoutValueKey {
  static let defaultValue: String? = nil
}

extension View {
  func lightName(_ name: String) -> some View {
    layoutValue(key: LightNameKey.self, value: name)
  }
}
