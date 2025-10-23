import HomeLights
import SwiftUI

struct LightCanvasView: View {
  let home: DiscoveredDevices.Home

  @State private var lightPositions: [String: CGPoint] = [:]
  @State private var selectedLights: Set<String> = []
  @State private var storage: JSONStorage?
  @State private var canvasSize: CGSize = .zero

  private var allLights: [DiscoveredDevices.Accessory] {
    home.rooms.flatMap { room in
      room.accessories.filter { $0.category == "Lightbulb" }
    }
  }

  var body: some View {
    VStack {
      // Available lights section
      if !availableLights.isEmpty {
        VStack(alignment: .leading, spacing: 8) {
          Text("Available Lights")
            .font(.headline)
            .padding(.horizontal)

          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
              ForEach(availableLights, id: \.name) { light in
                Button(action: { addLight(light) }) {
                  VStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                      .font(.title2)
                      .foregroundColor(.yellow)

                    Text(light.name)
                      .font(.caption)
                      .lineLimit(2)
                      .multilineTextAlignment(.center)
                  }
                  .frame(width: 80, height: 80)
                  .background(Color.secondary.opacity(0.1))
                  .cornerRadius(12)
                }
                .buttonStyle(.plain)
              }
            }
            .padding(.horizontal)
          }
          .frame(height: 100)
        }
        .padding(.vertical)
      }

      Divider()

      // Canvas area
      GeometryReader { geometry in
        ZStack {
          Color.black.opacity(0.05)
            .ignoresSafeArea()

          FreePlacementLayout(positions: $lightPositions) {
            ForEach(Array(selectedLights), id: \.self) { lightName in
              if let light = allLights.first(where: { $0.name == lightName }) {
                DraggableLightView(
                  light: light,
                  position: lightPositions[lightName] ?? CGPoint(
                    x: geometry.size.width / 2,
                    y: geometry.size.height / 2
                  ),
                  canvasSize: canvasSize,
                  onPositionChange: { newPosition in
                    lightPositions[lightName] = newPosition
                    savePositions()
                  },
                  onRemove: {
                    removeLight(lightName)
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
    .navigationTitle("\(home.name) Canvas")
    .task {
      setupStorage()
      loadPositions()
    }
  }

  private var availableLights: [DiscoveredDevices.Accessory] {
    allLights.filter { !selectedLights.contains($0.name) }
  }

  private func addLight(_ light: DiscoveredDevices.Accessory) {
    selectedLights.insert(light.name)
    // Will be positioned at center initially
    savePositions()
  }

  private func removeLight(_ lightName: String) {
    selectedLights.remove(lightName)
    lightPositions.removeValue(forKey: lightName)
    savePositions()
  }

  private func setupStorage() {
    do {
      storage = try JSONStorage()
    } catch {
      print("Failed to setup storage: \(error)")
    }
  }

  private func savePositions() {
    guard let storage = storage else { return }

    let data = LightPositionData(
      homeName: home.name,
      selectedLights: Array(selectedLights),
      positions: lightPositions
    )

    do {
      try storage.store(data, filename: "light-positions-\(home.name).json")
    } catch {
      print("Failed to save positions: \(error)")
    }
  }

  private func loadPositions() {
    guard let storage = storage else { return }

    do {
      if let data = try storage.load(
        LightPositionData.self,
        filename: "light-positions-\(home.name).json"
      ) {
        selectedLights = Set(data.selectedLights)
        lightPositions = data.positions
      }
    } catch {
      print("Failed to load positions: \(error)")
    }
  }
}

struct DraggableLightView: View {
  let light: DiscoveredDevices.Accessory
  let position: CGPoint
  let canvasSize: CGSize
  let onPositionChange: (CGPoint) -> Void
  let onRemove: () -> Void

  @State private var isDragging = false
  @State private var dragOffset: CGSize = .zero

  private let lightWidth: CGFloat = 80
  private let lightHeight: CGFloat = 100

  var body: some View {
    VStack(spacing: 8) {
      ZStack(alignment: .topTrailing) {
        Circle()
          .fill(light.displayColor)
          .frame(width: 60, height: 60)
          .shadow(color: light.displayColor.opacity(0.5), radius: 10)
          .overlay(
            Image(systemName: "lightbulb.fill")
              .font(.title2)
              .foregroundColor(.white)
          )

        Button(action: onRemove) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(.red)
            .background(Circle().fill(Color.white))
        }
        .buttonStyle(.plain)
        .offset(x: 8, y: -8)
      }

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
    .gesture(
      DragGesture(coordinateSpace: .local)
        .onChanged { value in
          isDragging = true
          dragOffset = value.translation
        }
        .onEnded { value in
          isDragging = false

          // Calculate new position with bounds checking
          var newX = position.x + value.translation.width
          var newY = position.y + value.translation.height

          // Clamp to canvas bounds
          let halfWidth = lightWidth / 2
          let halfHeight = lightHeight / 2

          newX = max(halfWidth, min(canvasSize.width - halfWidth, newX))
          newY = max(halfHeight, min(canvasSize.height - halfHeight, newY))

          let newPosition = CGPoint(x: newX, y: newY)

          // Reset offset and update position
          dragOffset = .zero
          onPositionChange(newPosition)
        }
    )
  }
}

// Custom Layout for free placement
struct FreePlacementLayout: Layout {
  @Binding var positions: [String: CGPoint]

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    proposal.replacingUnspecifiedDimensions()
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    for (index, subview) in subviews.enumerated() {
      let size = subview.sizeThatFits(.unspecified)

      // Get position from binding or use center
      let position: CGPoint
      if let name = subview[LightNameKey.self],
        let storedPosition = positions[name]
      {
        position = storedPosition
      } else {
        position = CGPoint(x: bounds.midX, y: bounds.midY)
      }

      // Place centered on the position
      let placementPoint = CGPoint(
        x: position.x - size.width / 2,
        y: position.y - size.height / 2
      )

      subview.place(at: placementPoint, proposal: .unspecified)
    }
  }
}

// Custom layout value key
struct LightNameKey: LayoutValueKey {
  static let defaultValue: String? = nil
}

extension View {
  func lightName(_ name: String) -> some View {
    layoutValue(key: LightNameKey.self, value: name)
  }
}

// Data model for storing positions
struct LightPositionData: Codable {
  let homeName: String
  let selectedLights: [String]
  let positions: [String: CGPoint]
}

extension CGPoint: Codable {
  enum CodingKeys: String, CodingKey {
    case x
    case y
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let x = try container.decode(CGFloat.self, forKey: .x)
    let y = try container.decode(CGFloat.self, forKey: .y)
    self.init(x: x, y: y)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(x, forKey: .x)
    try container.encode(y, forKey: .y)
  }
}
