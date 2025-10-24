import HomeLights
import SwiftUI

struct CanvasArea: View {
  let allLights: [DiscoveredDevices.Accessory]
  let selectedLights: Set<String>
  @Binding var lightPositions: [String: CGPoint]
  @Binding var canvasSize: CGSize
  let expectedColors: [String: HSBColor]
  let onPositionChange: (String, CGPoint) -> Void
  let onRemove: (String) -> Void

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        Color.black.opacity(0.05)
          .ignoresSafeArea()

        FreePlacementLayout(positions: $lightPositions) {
          ForEach(Array(selectedLights), id: \.self) { lightName in
            if let light = allLights.first(where: { $0.name == lightName }) {
              DraggableLightView(
                light: light,
                position: lightPositions[lightName]
                  ?? CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                  ),
                canvasSize: canvasSize,
                expectedColor: expectedColors[lightName],
                onPositionChange: { newPosition in
                  onPositionChange(lightName, newPosition)
                },
                onRemove: {
                  onRemove(lightName)
                }
              )
              .lightName(lightName)
            }
          }
        }
      }
      .onAppear {
        canvasSize = geometry.size
      }
      .onChange(of: geometry.size) { oldValue, newValue in
        canvasSize = newValue
      }
    }
  }
}
