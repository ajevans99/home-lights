import HomeLights
import SwiftUI

struct DraggableLightView: View {
  let light: DiscoveredDevices.Accessory
  let position: CGPoint
  let canvasSize: CGSize
  let expectedColor: HSBColor?
  let onPositionChange: (CGPoint) -> Void
  let onRemove: () -> Void

  @State private var isDragging = false
  @State private var dragOffset: CGSize = .zero

  private let lightWidth: CGFloat = 80
  private let lightHeight: CGFloat = 100

  private var displayColor: Color {
    if let expected = expectedColor {
      return Color(
        hue: expected.hue / 360.0,
        saturation: expected.saturation / 100.0,
        brightness: expected.brightness / 100.0
      )
    }
    return light.displayColor
  }

  var body: some View {
    VStack(spacing: 8) {
      Circle()
        .fill(displayColor)
        .frame(width: 60, height: 60)
        .shadow(color: displayColor.opacity(0.5), radius: 10)
        .overlay(
          Image(systemName: "lightbulb.fill")
            .font(.title2)
            .foregroundColor(.white)
        )
        .animation(.easeInOut(duration: 0.3), value: displayColor)

      Text(light.name)
        .font(.caption)
        .lineLimit(2)
        .multilineTextAlignment(.center)
        .frame(width: lightWidth)
    }
    .offset(x: dragOffset.width, y: dragOffset.height)
    .scaleEffect(isDragging ? 1.1 : 1.0)
    .opacity(isDragging ? 0.8 : 1.0)
    .animation(.easeInOut(duration: 0.2), value: isDragging)
    .contextMenu {
      Button(role: .destructive, action: onRemove) {
        Label("Remove from Canvas", systemImage: "trash")
      }
    }
    .gesture(
      DragGesture(coordinateSpace: .local)
        .onChanged { value in
          isDragging = true
          dragOffset = value.translation
        }
        .onEnded { value in
          isDragging = false

          var newX = position.x + value.translation.width
          var newY = position.y + value.translation.height

          let halfWidth = lightWidth / 2
          let halfHeight = lightHeight / 2

          newX = max(halfWidth, min(canvasSize.width - halfWidth, newX))
          newY = max(halfHeight, min(canvasSize.height - halfHeight, newY))

          let newPosition = CGPoint(x: newX, y: newY)

          dragOffset = .zero
          onPositionChange(newPosition)
        }
    )
  }
}
