import HomeLights
import SwiftUI

struct ContentView: View {
  @State private var devices: DiscoveredDevices?
  @State private var selectedHome: DiscoveredDevices.Home?
  @State private var isDiscovering = false
  @State private var errorMessage: String?

  @Environment(HomeLights.self) private var homeLights

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        if isDiscovering {
          ProgressView("Discovering HomeKit devices...")
        } else if let home = selectedHome {
          HomeView(home: home)
        } else {
          WelcomeView(
            errorMessage: errorMessage,
            onDiscover: discoverDevices
          )
        }
      }
      .navigationTitle("Home Lights")
      .onAppear { discoverDevices() }
      .toolbar {
        if let devices = devices, !devices.homes.isEmpty {
          ToolbarItem(placement: .primaryAction) {
            HomeSelectorMenu(
              devices: devices,
              selectedHome: $selectedHome
            )
          }
        }
      }
    }
  }

  private func discoverDevices() {
    isDiscovering = true
    errorMessage = nil

    Task {
      let discoveredDevices = await homeLights.discoverAccessories()

      await MainActor.run {
        self.devices = discoveredDevices
        self.isDiscovering = false

        if discoveredDevices.totalAccessories == 0 {
          self.errorMessage =
            "No devices found. Make sure HomeKit is set up and you've granted access."
        } else {
          // Default to primary home
          self.selectedHome =
            discoveredDevices.homes.first(where: { $0.isPrimary })
            ?? discoveredDevices.homes.first
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
