import HomeLights
import SwiftUI

let homeLights = HomeLights()

struct ContentView: View {
  @State private var devices: DiscoveredDevices?
  @State private var selectedHome: DiscoveredDevices.Home?
  @State private var isDiscovering = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationView {
      VStack(spacing: 20) {
        if isDiscovering {
          ProgressView("Discovering HomeKit devices...")
        } else if let home = selectedHome {
          HomeView(home: home)
        } else {
          VStack(spacing: 16) {
            Image(systemName: "lightbulb.fill")
              .imageScale(.large)
              .font(.system(size: 60))
              .foregroundStyle(.tint)

            Text("Home Lights")
              .font(.largeTitle)
              .fontWeight(.bold)

            Text("Discover and control your HomeKit devices")
              .font(.subheadline)
              .foregroundColor(.secondary)
              .multilineTextAlignment(.center)

            Button("Discover Devices") {
              discoverDevices()
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)

            if let errorMessage = errorMessage {
              Text(errorMessage)
                .foregroundColor(.red)
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding()
            }
          }
          .padding()
        }
      }
      .navigationTitle("Home Lights")
      .onAppear { discoverDevices() }
      .toolbar {
        if let devices = devices, !devices.homes.isEmpty {
          ToolbarItem(placement: .primaryAction) {
            Menu {
              ForEach(devices.homes, id: \.name) { home in
                Button(action: { selectedHome = home }) {
                  HStack {
                    Text(home.name)
                    if home.isPrimary {
                      Image(systemName: "star.fill")
                    }
                  }
                }
              }
            } label: {
              HStack {
                Text(selectedHome?.name ?? "Select Home")
                Image(systemName: "chevron.down")
              }
            }
          }
        }
      }
    }
  }

  private func discoverDevices() {
    isDiscovering = true
    errorMessage = nil

    homeLights.discoverAccessories { discoveredDevices in
      DispatchQueue.main.async {
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

struct HomeView: View {
  let home: DiscoveredDevices.Home

  var body: some View {
    VStack {
      List {
        ForEach(home.rooms, id: \.name) { room in
          DisclosureGroup {
            ForEach(room.accessories, id: \.name) { accessory in
              AccessoryRow(accessory: accessory)
            }
          } label: {
            HStack {
              Image(systemName: "door.left.hand.open")
              Text(room.name)
              Spacer()
              Text("\(room.accessories.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        }
      }

      NavigationLink(destination: LightCanvasView(home: home)) {
        HStack {
          Image(systemName: "rectangle.on.rectangle.angled")
          Text("Open Light Canvas")
          Spacer()
          Image(systemName: "chevron.right")
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(8)
      }
      .padding()
    }
  }
}

struct LightRow: View {
  let light: DiscoveredDevices.Accessory

  var body: some View {
    HStack {
      Image(systemName: "lightbulb.fill")
        .foregroundColor(light.displayColor)

      VStack(alignment: .leading, spacing: 4) {
        Text(light.name)
          .font(.body)

        if let room = light.room {
          Text(room)
            .font(.caption)
            .foregroundColor(.secondary)
        }

        Text(light.services.joined(separator: ", "))
          .font(.caption2)
          .foregroundColor(.secondary)
      }

      Spacer()

      Circle()
        .fill(light.isReachable ? Color.green : Color.gray)
        .frame(width: 8, height: 8)
    }
    .padding(.vertical, 4)
  }
}

extension DiscoveredDevices.Accessory {
  var displayColor: Color {
    guard isReachable else {
      return .gray
    }

    guard let colorInfo = lightColor else {
      return .yellow
    }

    let hue = (colorInfo.hue ?? 60) / 360.0
    let saturation = (colorInfo.saturation ?? 100) / 100.0
    let brightness = (colorInfo.brightness ?? 100) / 100.0

    return Color(hue: hue, saturation: saturation, brightness: brightness)
  }
}

struct AccessoryRow: View {
  let accessory: DiscoveredDevices.Accessory

  var body: some View {
    HStack {
      Image(systemName: iconName(for: accessory.category))
        .foregroundColor(accessory.isReachable ? .green : .gray)

      VStack(alignment: .leading, spacing: 4) {
        Text(accessory.name)
          .font(.body)

        Text(accessory.category)
          .font(.caption)
          .foregroundColor(.secondary)

        if let room = accessory.room {
          Text(room)
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }

      Spacer()

      Circle()
        .fill(accessory.isReachable ? Color.green : Color.gray)
        .frame(width: 8, height: 8)
    }
    .padding(.vertical, 4)
  }

  private func iconName(for category: String) -> String {
    switch category.lowercased() {
    case "lightbulb": return "lightbulb.fill"
    case "switch": return "switch.2"
    case "outlet": return "poweroutlet.type.b.fill"
    case "thermostat": return "thermometer"
    case "fan": return "fan.fill"
    case "door": return "door.left.hand.closed"
    case "window": return "rectangle.portrait.on.rectangle.portrait"
    case "garage door opener": return "garage.closed"
    case "security system": return "shield.fill"
    case "sensor": return "sensor.fill"
    case "bridge": return "network"
    default: return "cube.box.fill"
    }
  }
}

struct DeviceListView: View {
  let devices: DiscoveredDevices

  var body: some View {
    List {
      ForEach(devices.homes, id: \.name) { home in
        Section(
          header: HStack {
            Text(home.name)
            if home.isPrimary {
              Image(systemName: "star.fill")
                .foregroundColor(.yellow)
            }
          }
        ) {
          ForEach(home.rooms, id: \.name) { room in
            DisclosureGroup {
              ForEach(room.accessories, id: \.name) { accessory in
                AccessoryRow(accessory: accessory)
              }
            } label: {
              HStack {
                Image(systemName: "door.left.hand.open")
                Text(room.name)
                Spacer()
                Text("\(room.accessories.count)")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
        }
      }
    }
  }
}

#Preview {
  ContentView()
}
