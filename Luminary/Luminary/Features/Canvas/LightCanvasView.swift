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
  @State private var expectedColors: [String: HSBColor] = [:]
  @State private var currentTask: Task<Void, Never>?

  @Environment(LightShowRegistry.self) private var lightShowRegistry
  @Environment(HomeLights.self) private var homeLights

  private var allLights: [DiscoveredDevices.Accessory] {
    home.rooms.flatMap { room in
      room.accessories.filter { $0.category == "Lightbulb" }
    }
  }

  var body: some View {
    VStack {
      // Available lights section
      if !availableLights.isEmpty {
        AvailableLightsSection(
          lights: availableLights,
          onAdd: addLight
        )
      }

      Divider()

      // Canvas area
      CanvasArea(
        allLights: allLights,
        selectedLights: selectedLights,
        lightPositions: $lightPositions,
        canvasSize: $canvasSize,
        expectedColors: expectedColors,
        onPositionChange: { lightName, position in
          lightPositions[lightName] = position
          savePositions()
        },
        onRemove: removeLight
      )
    }
    .navigationTitle("\(home.name) Canvas")
    .toolbar {
      ToolbarItem(placement: .automatic) {
        Button(action: syncWithHomeKit) {
          HStack {
            Image(systemName: "arrow.triangle.2.circlepath")
            Text("Sync")
          }
        }
      }

      ToolbarItem(placement: .primaryAction) {
        Button(action: { showControlPanel.toggle() }) {
          Image(systemName: "sidebar.right")
        }
      }
    }
    .inspector(isPresented: $showControlPanel) {
      LightShowControlPanel(
        selectedShow: $selectedShow,
        lightPositions: getLightsWithPositions(),
        onApply: applyLightShow
      )
      .inspectorColumnWidth(min: 250, ideal: 400, max: 500)
      .presentationDetents([.medium, .large])
      .presentationBackgroundInteraction(.enabled)
    }
    .task {
      setupStorage()
      loadPositions()
    }
    .onDisappear {
      stopShow()
    }
  }

  private var availableLights: [DiscoveredDevices.Accessory] {
    allLights.filter { !selectedLights.contains($0.name) }
  }

  private func getLightsWithPositions() -> [(name: String, position: CGPoint)] {
    selectedLights.compactMap { lightName -> (String, CGPoint)? in
      guard let position = lightPositions[lightName] else { return nil }
      return (lightName, position)
    }
  }

  private func addLight(_ light: DiscoveredDevices.Accessory) {
    selectedLights.insert(light.name)
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

  private func syncWithHomeKit() {
    expectedColors.removeAll()
  }

  private func stopShow() {
    currentTask?.cancel()
    currentTask = nil
  }

  private func applyLightShow() {
    guard let show = selectedShow else { return }

    stopShow()

    let lights = getLightsWithPositions()
    guard !lights.isEmpty else { return }

    currentTask = show.apply(
      to: lights,
      using: homeLights,
      onColorUpdate: { [self] lightName, color in
        Task { @MainActor in
          self.expectedColors[lightName] = color
        }
      }
    )
  }
}

// MARK: - Data Model

struct LightPositionData: Codable {
  let homeName: String
  let selectedLights: [String]
  let positions: [String: CGPoint]
}
