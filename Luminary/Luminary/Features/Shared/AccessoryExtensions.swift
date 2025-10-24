import HomeLights
import SwiftUI

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
