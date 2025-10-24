import HomeLights
import SwiftUI

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
