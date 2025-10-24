import HomeLights
import SwiftUI

struct LightCanvasView: View {
  let home: DiscoveredDevices.Home

  @State private var lightPositions: [String: CGPoint] = [:]
  @State private var selectedLights: Set<String> = []
  @State private var storage: JSONStorage?
  @State private var canvasSize: CGSize = .zero
  @State private var selectedShow: (any LightShow)?
  @State private var showControlPanel = true

  @Environment(LightShowRegistry.self) private var lightShowRegistry
  @Environment(HomeLights.self) private var homeLights

  private var allLights: [DiscoveredDevices.Accessory] {
    home.rooms.flatMap { room in
      room.accessories.filter { $0.category == "Lightbulb" }
    }
  }

  var body: some View {
    HStack(spacing: 0) {
      // Main canvas area
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
                    position: lightPositions[lightName]
                      ?? CGPoint(
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

      // Right control panel
      if showControlPanel {
        Divider()

        LightShowControlPanel(
          selectedShow: $selectedShow,
          onApply: applyLightShow
        )
        .frame(width: 300)
        .background(Color(uiColor: .systemGroupedBackground))
      }
    }
    .navigationTitle("\(home.name) Canvas")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(action: { showControlPanel.toggle() }) {
          Image(systemName: showControlPanel ? "sidebar.right" : "sidebar.right.filled")
        }
      }
    }
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

  private func applyLightShow() {
    guard let show = selectedShow else { return }

    // Apply the light show to all selected lights
    for lightName in selectedLights {
      guard let position = lightPositions[lightName] else { continue }

      // Get color from the show for this light
      if let hsbColor = show.color(for: lightName, at: position, time: 0) {
        // Apply color to actual HomeKit light
        homeLights.setLightColor(
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

struct LightShowControlPanel: View {
  @Binding var selectedShow: (any LightShow)?
  let onApply: () -> Void

  @Environment(LightShowRegistry.self) private var registry

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header
      VStack(alignment: .leading, spacing: 8) {
        Text("Light Shows")
          .font(.title2)
          .fontWeight(.bold)

        Text("Select and configure light sequences")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .padding()

      Divider()

      // Show list
      ScrollView {
        VStack(spacing: 12) {
          ForEach(registry.availableShows, id: \.id) { show in
            LightShowCard(
              show: show,
              isSelected: selectedShow?.id == show.id,
              onSelect: {
                selectedShow = show
              }
            )
          }
        }
        .padding()
      }

      Divider()

      // Configuration area
      if let show = selectedShow {
        VStack(alignment: .leading, spacing: 12) {
          Text("Configuration")
            .font(.headline)

          show.configurationView()

          Spacer()

          Button(action: onApply) {
            HStack {
              Image(systemName: "play.fill")
              Text("Apply Light Show")
            }
            .frame(maxWidth: .infinity)
          }
          .buttonStyle(.borderedProminent)
        }
        .padding()
      } else {
        VStack {
          Spacer()
          Text("Select a light show to configure")
            .font(.caption)
            .foregroundColor(.secondary)
          Spacer()
        }
        .frame(maxHeight: 200)
      }
    }
  }
}

struct LightShowCard: View {
  let show: any LightShow
  let isSelected: Bool
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: 12) {
        Image(systemName: show.icon)
          .font(.title2)
          .foregroundColor(isSelected ? .white : .accentColor)
          .frame(width: 40, height: 40)
          .background(
            isSelected
              ? Color.accentColor
              : Color.accentColor.opacity(0.1)
          )
          .cornerRadius(8)

        VStack(alignment: .leading, spacing: 4) {
          Text(show.name)
            .font(.headline)
            .foregroundColor(.primary)

          Text(show.description)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(2)
        }

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.accentColor)
        }
      }
      .padding()
      .background(
        isSelected
          ? Color.accentColor.opacity(0.1)
          : Color.clear
      )
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            isSelected ? Color.accentColor : Color.clear,
            lineWidth: 2
          )
      )
    }
    .buttonStyle(.plain)
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

  func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    for subview in subviews {
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
